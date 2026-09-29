# frozen_string_literal: true

require "test_helper"

# #707 — Bali::ContentVersionsController. The whitelist and the gate are injected through config,
# the same way a host does it (pattern from test/requests/saved_views_test.rb).
#
# The JSON contract is not negotiable: `document_editor/index.js` is already published and reads
# specific keys. `_buildVersionItem` (:355-369) uses version_number, created_at, author_name,
# summary, id and url; `previewVersion` (:253-299) uses content and version_number;
# `restoreVersion` (:238-246) only checks that the response is ok.
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
    # The JS prefers this url over interpolating one: the engine may be mounted anywhere.
    assert_equal bali.content_version_path(newest["id"], record_params), newest["url"]
    assert_equal @document.content_versions.last.created_at.iso8601, newest["created_at"]
  end

  # Security review finding (MEDIUM-2): the index did a SELECT * and pulled every version's `content`
  # —the whole document— without serving it. With 200 versions that was 31.5 MB read for a 22.6 KB
  # body. What this test pins is that trimming the columns did NOT change the contract: exactly the
  # same keys, and none of them is the content.
  def test_index_serves_no_content_and_only_the_columns_it_needs
    3.times { @document.create_version!(author_name: "Ana", summary: "s") }

    get bali.content_versions_path(record_params), as: :json
    assert_response :success

    payload = response.parsed_body
    assert_equal 3, payload.size
    payload.each do |version|
      assert_equal %w[author_name created_at id summary url version_number], version.keys.sort
      refute_includes version.keys, "content"
      refute_includes version.keys, "metadata"
    end
  end

  # MEDIUM-2's other half: trimming columns cannot leave `version_json` reading an attribute that is
  # no longer selected (that would be a MissingAttributeError in production).
  def test_index_does_not_load_the_content_column_at_all
    @document.create_version!(author_name: "Ana")

    loaded = @document.content_versions.newest_first
                      .select(*Bali::ContentVersionsController::INDEX_COLUMNS).first

    refute loaded.has_attribute?(:content)
    assert_raises(ActiveModel::MissingAttributeError) { loaded.content }
  end

  def test_index_is_empty_for_a_record_without_versions
    get bali.content_versions_path(record_params), as: :json
    assert_response :success
    assert_empty response.parsed_body
  end

  # The index's url has to resolve as is, with the JS adding nothing to it.
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

  # Default-deny: an empty whitelist is the factory setting.
  def test_a_record_type_outside_the_whitelist_is_not_found
    Bali.content_versionables = {}

    get bali.content_versions_path(record_params), as: :json
    assert_response :not_found
  end

  def test_an_unknown_record_type_is_not_found_even_with_a_whitelist
    get bali.content_versions_path(record_type: "User", record_id: @user.id), as: :json
    assert_response :not_found
  end

  # Security review finding (LOW-4): whitelisting a model that never included the concern is a host
  # configuration error, and it answered 500 (NoMethodError on `content_versions`) instead of 404.
  def test_a_whitelisted_model_without_the_concern_is_not_found
    studio = Studio.create!(name: "Sin historial", country: "USA", status: :active)
    refute_kind_of Bali::ContentVersionable, studio
    Bali.content_versionables = { "Studio" => ->(_controller, id) { Studio.find_by(id: id) } }

    get bali.content_versions_path(record_type: "Studio", record_id: studio.id), as: :json
    assert_response :not_found

    post bali.restore_content_versions_path(record_type: "Studio", record_id: studio.id),
         params: { version_id: 1 }, as: :json
    assert_response :not_found
  end

  def test_a_resolver_that_returns_nothing_is_not_found
    get bali.content_versions_path(record_type: "Document", record_id: 0), as: :json
    assert_response :not_found
  end

  # The default lib/bali.rb ships is exactly this lambda; it is written out here because the dummy's
  # initializer overrides it for the demo.
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

  # The gate receives the action, so reading and restoring can be told apart.
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
