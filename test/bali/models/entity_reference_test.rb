# frozen_string_literal: true

require "test_helper"

class BaliEntityReferenceTest < ActiveSupport::TestCase
  def setup
    @original_types = Bali.entity_reference_types
    @document = Document.create!(title: "Contenedor", author_name: "Ana", content: [])
  end

  def teardown
    Bali.entity_reference_types = @original_types
  end

  def build_reference(**attrs)
    Bali::EntityReference.new(
      { record: @document, referenceable_type: "Project", referenceable_id: 1,
        reference_text: "Bali" }.merge(attrs)
    )
  end

  test "valid with a record and a polymorphic referenceable" do
    assert_predicate build_reference, :valid?
  end

  test "the same entity cannot be referenced twice from the same record" do
    build_reference.save!

    assert_not build_reference.valid?, "el par record+referenceable debe ser único"
    assert_predicate build_reference(referenceable_id: 2), :valid?
    assert_predicate build_reference(referenceable_type: "Task"), :valid?
    assert_predicate build_reference(record: Document.create!(title: "Otro", author_name: "Ana")), :valid?
  end

  test "survives the disappearance of the referenced record" do
    project = Project.create!(name: "Se va a borrar")
    reference = build_reference(referenceable: project)
    reference.save!

    project.destroy!

    # Sin foreign key: la fila sobrevive para pintarse como chip roto. Un ON DELETE la
    # habría borrado y el lector perdería la señal de que ahí decía algo.
    assert_predicate reference.reload, :persisted?
    assert_nil reference.referenceable
    assert_predicate reference, :broken?
  end

  test "broken? asks the registry's unreachable? for the type" do
    archived = Document.create!(title: "Archivado", author_name: "Ana", status: :archived)
    Bali.entity_reference_types = {
      "Document" => { search_scope: -> { Document.all }, lookup_scope: -> { Document.all },
                      search_fields: %i[title], display_field: :title,
                      unreachable?: ->(doc) { doc.nil? || doc.archived? } }
    }
    reference = build_reference(referenceable: archived)

    assert_predicate reference, :broken?
    assert_not reference.reachable?
  end

  test "a present record of an unregistered type is reachable" do
    Bali.entity_reference_types = {}

    assert_predicate build_reference(referenceable: Project.create!(name: "Vivo")), :reachable?
  end

  test "to scopes the rows pointing at an entity" do
    project = Project.create!(name: "Referenciado")
    mine = build_reference(referenceable: project)
    mine.save!
    build_reference(referenceable_id: project.id + 1000).save!

    assert_equal [ mine ], Bali::EntityReference.to(project).to_a
  end
end
