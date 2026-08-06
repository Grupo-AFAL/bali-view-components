# frozen_string_literal: true

require "test_helper"

# #708 — el concern que materializa las referencias embebidas en contenido BlockNote.
# Los fixtures son JSON de BlockNote REAL (el que produce el editor), no una versión
# simplificada: los dos shapes de tabla y los children anidados son justamente donde un
# walker propio se equivoca.
class BaliEntityReferenceableTest < ActiveSupport::TestCase
  # Un modelo con la columna JSON en otro nombre, para el macro `references_entities_in`.
  # BlockEditorThread sirve porque su `metadata` es json y no exige asociaciones.
  class ReferencingThread < BlockEditorThread
    include Bali::EntityReferenceable
    references_entities_in :metadata
  end

  def setup
    @original_types = Bali.entity_reference_types
    Bali.entity_reference_types = {
      "Project" => { search_scope: -> { Project.all }, lookup_scope: -> { Project.all },
                     search_fields: %i[name], display_field: :name },
      "Task" => { search_scope: -> { Task.all }, lookup_scope: -> { Task.all },
                  search_fields: %i[title], display_field: :title }
    }
  end

  def teardown
    Bali.entity_reference_types = @original_types
  end

  def document(content: [])
    Document.create!(title: "Referencias", author_name: "Ana", content: content)
  end

  def reference_node(type, id, name)
    { "type" => "entityReference",
      "props" => { "entityType" => type, "entityId" => id.to_s, "entityName" => name } }
  end

  def paragraph(*nodes, id: "p1")
    { "id" => id, "type" => "paragraph", "props" => {}, "content" => nodes, "children" => [] }
  end

  def keys_of(doc)
    doc.entity_references.pluck(:referenceable_type, :referenceable_id).sort
  end

  # Extracción

  test "materializes references embedded in a paragraph" do
    doc = document(content: [
      paragraph({ "type" => "text", "text" => "Ver ", "styles" => {} },
                reference_node("Project", 7, "Bali"),
                { "type" => "text", "text" => " y ", "styles" => {} },
                reference_node("Task", 3, "Kanban"))
    ])

    assert_equal [ [ "Project", 7 ], [ "Task", 3 ] ], keys_of(doc)
    assert_equal %w[Bali Kanban], doc.entity_references.order(:referenceable_type).pluck(:reference_text)
  end

  test "materializes references inside tableContent cells" do
    table = {
      "id" => "t1", "type" => "table", "props" => {}, "children" => [],
      "content" => {
        "type" => "tableContent",
        "rows" => [
          { "cells" => [ { "content" => [ { "type" => "text", "text" => "Responsable", "styles" => {} } ] },
                         { "content" => [ reference_node("Project", 9, "Migración") ] } ] }
        ]
      }
    }

    assert_equal [ [ "Project", 9 ] ], keys_of(document(content: [ table ]))
  end

  test "materializes references inside nested children" do
    outer = paragraph({ "type" => "text", "text" => "Padre", "styles" => {} }, id: "outer")
    outer["children"] = [ paragraph(reference_node("Task", 11, "Hijo"), id: "inner") ]

    assert_equal [ [ "Task", 11 ] ], keys_of(document(content: [ outer ]))
  end

  test "ignores references to types outside the registry" do
    doc = document(content: [
      paragraph(reference_node("Task", 3, "Registrado"),
                reference_node("Secret", 1, "Sin registrar"))
    ])

    assert_equal [ [ "Task", 3 ] ], keys_of(doc)
  end

  test "ignores references whose id is not numeric" do
    doc = document(content: [
      paragraph(reference_node("Task", "550e8400-e29b-41d4-a716-446655440000", "UUID"),
                reference_node("Task", 3, "Numérico"))
    ])

    # `referenceable_id` es bigint: un `to_i` sobre el UUID guardaría 550 en silencio.
    assert_equal [ [ "Task", 3 ] ], keys_of(doc)
  end

  test "ignores an id too large for the bigint column instead of losing the save" do
    doc = document(content: [
      paragraph(reference_node("Task", "99999999999999999999", "Desbordado"),
                reference_node("Task", 3, "Cabe"))
    ])

    # Sin la cota, la coerción levanta ActiveModel::RangeError DENTRO del after_save y tira
    # el `update!` del usuario: el documento se vuelve imposible de guardar.
    assert_equal [ [ "Task", 3 ] ], keys_of(doc)
    assert_predicate doc.reload, :persisted?
  end

  test "caps how many references one record materializes" do
    max = Bali::EntityReferenceable::MAX_REFERENCES
    nodes = Array.new(max + 25) { |i| reference_node("Task", i + 1, "Tarea #{i}") }

    doc = document(content: [ paragraph(*nodes) ])

    assert_equal max, doc.entity_references.count
  end

  test "truncates the reference text the client wrote" do
    doc = document(content: [ paragraph(reference_node("Task", 3, "T" * 5_000)) ])

    assert_equal Bali::EntityReferenceable::MAX_REFERENCE_TEXT,
                 doc.entity_references.sole.reference_text.length
  end

  test "collapses repeated references to the same entity into one row" do
    doc = document(content: [
      paragraph(reference_node("Task", 3, "Primera"), id: "a"),
      paragraph(reference_node("Task", 3, "Segunda"), id: "b")
    ])

    assert_equal 1, doc.entity_references.count
    assert_equal "Primera", doc.entity_references.first.reference_text
  end

  test "reads the attribute named by references_entities_in" do
    thread = ReferencingThread.create!(
      metadata: { "content" => [ paragraph(reference_node("Project", 4, "Otra columna")) ] }
    )

    assert_equal [ [ "Project", 4 ] ], thread.entity_references.pluck(:referenceable_type, :referenceable_id)
  end

  # Diff mínimo — el editor autosalva, así que esto corre en cada guardado

  test "editing the text around a reference leaves its row untouched" do
    doc = document(content: [
      paragraph({ "type" => "text", "text" => "Antes ", "styles" => {} },
                reference_node("Task", 3, "Kanban"))
    ])
    row = doc.entity_references.sole

    doc.update!(content: [
      paragraph({ "type" => "text", "text" => "Texto reescrito ", "styles" => {} },
                reference_node("Task", 3, "Kanban"))
    ])

    # El id sobrevive al guardado: el diff no borra y recrea lo que no cambió, que es lo
    # que permite colgar cosas de una referencia.
    assert_equal row.id, doc.entity_references.reload.sole.id
    assert_equal row.created_at, doc.entity_references.sole.created_at
  end

  test "saving another attribute does not touch the references table at all" do
    doc = document(content: [ paragraph(reference_node("Task", 3, "Kanban")) ])

    # El early-return por `saved_change_to_<attribute>?`: el editor autosalva, y sin él cada
    # guardado paga la extracción y el diff completo aunque el contenido no se haya tocado.
    assert_no_queries_matching(/bali_entity_references/) do
      doc.update!(title: "Otro título")
    end
  end

  test "adding a reference keeps the ids of the ones that stayed" do
    doc = document(content: [ paragraph(reference_node("Task", 3, "Kanban")) ])
    kept = doc.entity_references.sole

    doc.update!(content: [
      paragraph(reference_node("Task", 3, "Kanban"), id: "a"),
      paragraph(reference_node("Project", 7, "Bali"), id: "b")
    ])

    assert_equal [ [ "Project", 7 ], [ "Task", 3 ] ], keys_of(doc.reload)
    assert_equal kept.id, doc.entity_references.find_by(referenceable_type: "Task").id
  end

  test "removing a reference from the content deletes only that row" do
    doc = document(content: [
      paragraph(reference_node("Task", 3, "Kanban"), id: "a"),
      paragraph(reference_node("Project", 7, "Bali"), id: "b")
    ])
    kept = doc.entity_references.find_by(referenceable_type: "Project")

    doc.update!(content: [ paragraph(reference_node("Project", 7, "Bali"), id: "b") ])

    assert_equal [ [ "Project", 7 ] ], keys_of(doc.reload)
    assert_equal kept.id, doc.entity_references.sole.id
  end

  test "emptying the content clears the references" do
    doc = document(content: [ paragraph(reference_node("Task", 3, "Kanban")) ])

    doc.update!(content: [])

    assert_empty doc.entity_references.reload
  end

  test "destroying the record destroys its references" do
    doc = document(content: [ paragraph(reference_node("Task", 3, "Kanban")) ])

    assert_difference "Bali::EntityReference.count", -1 do
      doc.destroy!
    end
  end

  # Consultas inversas

  test "referencing finds the records whose content mentions an entity" do
    project = Project.create!(name: "Referenciado")
    doc = document(content: [ paragraph(reference_node("Project", project.id, project.name)) ])
    document(content: [ paragraph(reference_node("Task", 3, "Otra cosa")) ])

    assert_equal [ doc ], Document.referencing(project).to_a
  end

  test "incoming_references returns the rows pointing at this record" do
    referenced = document(content: [])
    Bali.entity_reference_types = Bali.entity_reference_types.merge(
      "Document" => { search_scope: -> { Document.all }, lookup_scope: -> { Document.all },
                      search_fields: %i[title], display_field: :title }
    )
    citing = document(content: [ paragraph(reference_node("Document", referenced.id, referenced.title)) ])

    assert_equal [ citing ], referenced.incoming_references.map(&:record)
  end

  private

  def assert_no_queries_matching(pattern)
    matched = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      matched << payload[:sql] if payload[:sql]&.match?(pattern)
    end
    yield
    assert_empty matched, "no se esperaban queries #{pattern.inspect}"
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
