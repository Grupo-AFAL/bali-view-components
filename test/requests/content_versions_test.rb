# frozen_string_literal: true

require "test_helper"

# #707 — Bali::ContentVersionsController. La whitelist y el gate se inyectan por config,
# igual que hace un host (patrón de test/requests/saved_views_test.rb).
#
# El contrato JSON no es negociable: `document_editor/index.js` ya está publicado y lee
# claves concretas. `_buildVersionItem` (:355-369) usa version_number, created_at,
# author_name, summary, id y url; `previewVersion` (:253-299) usa content y version_number;
# `restoreVersion` (:238-246) solo mira que la respuesta sea ok.
class BaliContentVersionsRequestTest < ActionDispatch::IntegrationTest
  def setup
    @document = Document.create!(title: "Acta", author_name: "Ana",
                                 content: [ { "type" => "paragraph", "id" => "a" } ])
    @user = User.create!(name: "Ana")

    @orig_versionables = Bali.content_versionables
    @orig_authorize = Bali.content_versions_authorize
    @orig_author = Bali.content_versions_author

    Bali.content_versionables = { "Document" => ->(_controller, id) { Document.find_by(id: id) } }
    Bali.content_versions_authorize = ->(_controller, _record, _action) { true }
    author = @user
    Bali.content_versions_author = ->(_controller) { [ author, author.name ] }
  end

  def teardown
    Bali.content_versionables = @orig_versionables
    Bali.content_versions_authorize = @orig_authorize
    Bali.content_versions_author = @orig_author
  end

  def record_params = { record_type: "Document", record_id: @document.id }

  def test_index_serves_every_key_the_versions_panel_reads_newest_first
    @document.create_version!(author_name: "Ana", summary: "Primera")
    @document.update!(content: [ { "type" => "paragraph", "id" => "b" } ])
    @document.create_version!(author: @user, author_name: "Ana García")

    get bali.content_versions_path(record_params), as: :json
    assert_response :success

    payload = response.parsed_body
    assert_equal [ 2, 1 ], payload.map { |v| v["version_number"] }

    newest = payload.first
    assert_equal %w[author_name created_at id summary url version_number], newest.keys.sort
    assert_equal "Ana García", newest["author_name"]
    assert_nil newest["summary"]
    assert_equal @document.content_versions.last.id, newest["id"]
    # El JS prefiere esta url sobre interpolarla: el engine puede estar montado donde sea.
    assert_equal bali.content_version_path(newest["id"], record_params), newest["url"]
    assert_equal @document.content_versions.last.created_at.iso8601, newest["created_at"]
  end

  def test_index_is_empty_for_a_record_without_versions
    get bali.content_versions_path(record_params), as: :json
    assert_response :success
    assert_empty response.parsed_body
  end

  # La url del index tiene que resolver tal cual, sin que el JS le agregue nada.
  def test_show_serves_the_content_the_preview_loads_into_the_editor
    version = @document.create_version!(author_name: "Ana", summary: "Primera")
    @document.update!(content: [])

    get bali.content_version_path(version, record_params), as: :json
    assert_response :success

    payload = response.parsed_body
    assert_equal [ { "type" => "paragraph", "id" => "a" } ], payload["content"]
    assert_equal 1, payload["version_number"]
    assert_equal "Primera", payload["summary"]
    assert_equal({}, payload["metadata"])
  end

  def test_show_of_a_version_belonging_to_another_record_is_not_found
    other = Document.create!(title: "Otra", author_name: "Ana")
    foreign = other.create_version!(author_name: "Ana")

    get bali.content_version_path(foreign, record_params), as: :json
    assert_response :not_found
  end

  def test_restore_puts_the_content_back_and_leaves_a_version_signed_by_the_configured_author
    version = @document.create_version!(author_name: "Ana")
    @document.update!(content: [ { "type" => "paragraph", "id" => "b" } ])
    @document.create_version!(author_name: "Ana")

    post bali.restore_content_versions_path(record_params),
         params: { version_id: version.id }, as: :json
    assert_response :success

    assert_equal [ { "type" => "paragraph", "id" => "a" } ], @document.reload.content
    restored = @document.content_versions.last
    assert_equal "Restored from v1", restored.summary
    assert_equal @user, restored.author
    assert_equal "Ana", restored.author_name
    assert_equal 3, response.parsed_body["version_number"]
  end

  # Default-deny: la whitelist vacía es la configuración de fábrica.
  def test_a_record_type_outside_the_whitelist_is_not_found
    Bali.content_versionables = {}

    get bali.content_versions_path(record_params), as: :json
    assert_response :not_found
  end

  def test_an_unknown_record_type_is_not_found_even_with_a_whitelist
    get bali.content_versions_path(record_type: "User", record_id: @user.id), as: :json
    assert_response :not_found
  end

  def test_a_resolver_that_returns_nothing_is_not_found
    get bali.content_versions_path(record_type: "Document", record_id: 0), as: :json
    assert_response :not_found
  end

  # El default que trae lib/bali.rb es exactamente este lambda; aquí se escribe explícito
  # porque el initializer del dummy lo sobreescribe para la demo.
  def test_a_falsy_authorize_forbids_every_action
    Bali.content_versions_authorize = ->(_controller, _record, _action) { false }
    version = @document.create_version!(author_name: "Ana")

    get bali.content_versions_path(record_params), as: :json
    assert_response :forbidden

    get bali.content_version_path(version, record_params), as: :json
    assert_response :forbidden

    post bali.restore_content_versions_path(record_params),
         params: { version_id: version.id }, as: :json
    assert_response :forbidden
  end

  # El gate recibe la acción, así que leer y restaurar se pueden separar.
  def test_authorize_can_allow_reading_and_forbid_restoring
    Bali.content_versions_authorize = ->(_controller, _record, action) { action != "restore" }
    version = @document.create_version!(author_name: "Ana")

    get bali.content_versions_path(record_params), as: :json
    assert_response :success

    assert_no_difference "Bali::ContentVersion.count" do
      post bali.restore_content_versions_path(record_params),
           params: { version_id: version.id }, as: :json
    end
    assert_response :forbidden
  end

  def test_restore_of_a_version_belonging_to_another_record_is_not_found
    other = Document.create!(title: "Otra", author_name: "Ana")
    foreign = other.create_version!(author_name: "Ana")

    post bali.restore_content_versions_path(record_params),
         params: { version_id: foreign.id }, as: :json
    assert_response :not_found
  end
end
