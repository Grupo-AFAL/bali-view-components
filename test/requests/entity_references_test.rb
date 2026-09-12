# frozen_string_literal: true

require "test_helper"

# #708 — los endpoints del `#` del BlockEditor. El registry se inyecta por config, igual que
# hace el host en su initializer; el contrato del payload se verifica clave por clave porque
# es lo que el JS ya consume (useEntityReferences.jsx) y no se puede cambiar.
class BaliEntityReferencesRequestTest < ActionDispatch::IntegrationTest
  def setup
    @original_types = Bali.entity_reference_types
    @original_authorize = Bali.entity_references_authorize

    @project = Project.create!(name: "Bali Components")
    @other_project = Project.create!(name: "Bali Interno")
    @document = Document.create!(title: "Bali Roadmap", author_name: "Ana", status: :published)
    @archived = Document.create!(title: "Bali Archivado", author_name: "Ana", status: :archived)

    Bali.entity_references_authorize = ->(_controller) { true }
    Bali.entity_reference_types = {
      "Document" => {
        search_scope: -> { Document.where.not(status: :archived) },
        lookup_scope: -> { Document.all },
        search_fields: %i[title],
        display_field: :title,
        url: ->(doc) { "/documents/#{doc.id}" },
        unreachable?: ->(doc) { doc.nil? || doc.archived? },
        extra_payload: ->(doc) { { entityTypeLabel: doc.status } }
      },
      "Project" => {
        search_scope: -> { Project.all },
        lookup_scope: -> { Project.all },
        search_fields: %i[name],
        display_field: :name,
        url: ->(project) { "/projects/#{project.id}" }
      }
    }
  end

  def teardown
    Bali.entity_reference_types = @original_types
    Bali.entity_references_authorize = @original_authorize
  end

  def json = JSON.parse(response.body)

  def with_type(type, **overrides)
    Bali.entity_reference_types = Bali.entity_reference_types.merge(
      type => Bali.entity_reference_types.fetch(type).merge(overrides)
    )
  end

  # Autorización

  test "a falsy authorize forbids both endpoints" do
    # El engine SHIPPEA este lambda como default (lib/bali.rb): montarlo no publica un
    # buscador de los registros del host hasta que la app lo abre a mano.
    Bali.entity_references_authorize = ->(_controller) { false }

    get bali.entity_references_path(q: "Bali")
    assert_response :forbidden

    post bali.resolve_entity_references_path, params: { refs: [] }, as: :json
    assert_response :forbidden
  end

  # Búsqueda

  test "search returns every registered type matching the query" do
    get bali.entity_references_path(q: "Bali")

    assert_response :success
    assert_equal %w[Document Project Project], json.map { |r| r["entityType"] }.sort
  end

  test "search escapes LIKE wildcards instead of matching everything" do
    get bali.entity_references_path(q: "%")

    assert_response :success
    assert_empty json, "el % debe buscarse literal, no como comodín"
  end

  test "search only offers what search_scope allows" do
    get bali.entity_references_path(q: "Bali")

    titles = json.select { |r| r["entityType"] == "Document" }.map { |r| r["entityName"] }
    assert_equal [ @document.title ], titles, "el archivado está fuera de search_scope"
  end

  test "search applies the type's permission_scope with the controller" do
    with_type("Project", permission_scope: lambda { |controller, scope|
      assert_kind_of Bali::EntityReferencesController, controller
      scope.where(id: @project.id)
    })

    get bali.entity_references_path(q: "Bali")

    projects = json.select { |r| r["entityType"] == "Project" }
    assert_equal [ @project.name ], projects.map { |r| r["entityName"] }
  end

  test "search caps the results at ten and at five per type" do
    8.times { |i| Project.create!(name: "Bali Extra #{i}") }
    6.times { |i| Document.create!(title: "Bali Doc #{i}", author_name: "Ana", status: :draft) }

    get bali.entity_references_path(q: "Bali")

    assert_equal 10, json.size
    assert_equal 5, json.count { |r| r["entityType"] == "Document" }
  end

  test "search without a query returns nothing" do
    get bali.entity_references_path

    assert_response :success
    assert_empty json
  end

  test "search ignores a query too short to narrow anything" do
    # Una sola letra recorre TODOS los tipos con un LIKE que no usa índice, y el menú pide
    # por tecleo: el primer caracter no vale ese barrido.
    get bali.entity_references_path(q: "B")

    assert_response :success
    assert_empty json
  end

  # Resolución

  test "resolve returns the frozen payload key by key" do
    post bali.resolve_entity_references_path,
         params: { refs: [ { entityType: "Project", entityId: @project.id.to_s } ] }, as: :json

    assert_response :success
    assert_equal(
      { "entityType" => "Project", "entityId" => @project.id.to_s, "entityName" => @project.name,
        "url" => "/projects/#{@project.id}", "broken" => false },
      json.sole
    )
  end

  test "resolve mixes existing, unreachable, deleted and unregistered refs" do
    post bali.resolve_entity_references_path, params: {
      refs: [
        { entityType: "Document", entityId: @document.id.to_s },
        { entityType: "Document", entityId: @archived.id.to_s },
        { entityType: "Document", entityId: "999999" },
        { entityType: "Secret", entityId: "1" }
      ]
    }, as: :json

    assert_response :success
    resolved = json.index_by { |ref| [ ref["entityType"], ref["entityId"] ] }

    assert_not resolved[[ "Document", @document.id.to_s ]]["broken"]
    # Archivado: se resuelve CON nombre y marcado como roto — el chip se pinta tachado en
    # vez de desaparecer del texto.
    archived = resolved[[ "Document", @archived.id.to_s ]]
    assert archived["broken"]
    assert_equal @archived.title, archived["entityName"]
    # Borrado y tipo fuera del registry: mismo payload roto, sin nombre ni URL.
    [ [ "Document", "999999" ], [ "Secret", "1" ] ].each do |key|
      assert resolved[key]["broken"], "#{key.inspect} debe venir roto"
      assert_nil resolved[key]["entityName"]
      assert_nil resolved[key]["url"]
    end
  end

  test "extra_payload adds host keys without overwriting the contract" do
    with_type("Document", extra_payload: ->(doc) { { entityTypeLabel: doc.status, broken: false } })

    post bali.resolve_entity_references_path,
         params: { refs: [ { entityType: "Document", entityId: @archived.id.to_s } ] }, as: :json

    payload = json.sole
    assert_equal "archived", payload["entityTypeLabel"]
    assert payload["broken"], "un extra_payload no puede convertir un roto en alcanzable"
  end

  test "resolve hides behind permission_scope what the viewer may not see" do
    with_type("Project", permission_scope: ->(_controller, scope) { scope.where(id: @project.id) })

    post bali.resolve_entity_references_path, params: {
      refs: [ { entityType: "Project", entityId: @other_project.id.to_s } ]
    }, as: :json

    payload = json.sole
    assert payload["broken"]
    assert_nil payload["entityName"], "no se filtra el nombre de un registro fuera del alcance"
  end

  test "resolve ignores anything beyond the two contract keys" do
    post bali.resolve_entity_references_path, params: {
      refs: [ { entityType: "Project", entityId: @project.id.to_s, scope: "Document.all" } ]
    }, as: :json

    assert_response :success
    assert_equal @project.name, json.sole["entityName"]
  end

  test "resolve caps how many refs one request may ask for" do
    refs = Array.new(Bali::EntityReferencesController::MAX_REFS + 20) do |i|
      { entityType: "Project", entityId: (i + 1).to_s }
    end

    post bali.resolve_entity_references_path, params: { refs: refs }, as: :json

    assert_response :success
    assert_equal Bali::EntityReferencesController::MAX_REFS, json.size
  end

  test "the GET endpoint also resolves when refs travel in the query string" do
    get bali.entity_references_path(refs: [ { entityType: "Project", entityId: @project.id.to_s } ])

    assert_response :success
    assert_equal @project.name, json.sole["entityName"]
  end
end
