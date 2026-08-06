# frozen_string_literal: true

require "test_helper"

# #707 — el historial que el engine le presta a un modelo del host. `Document` (del dummy)
# incluye el concern, así que estas pruebas ejercitan exactamente la adopción que se le pide
# a una app real.
class BaliContentVersionableTest < ActiveSupport::TestCase
  def setup
    @document = Document.create!(title: "Acta", author_name: "Ana",
                                 content: [ { "type" => "paragraph", "id" => "a" } ])
    @ana = User.create!(name: "Ana")
    @beto = User.create!(name: "Beto")
  end

  def test_create_version_snapshots_the_versioned_attribute_and_numbers_from_one
    version = @document.create_version!(author_name: "Ana", summary: "Primera")

    assert_equal 1, version.version_number
    assert_equal @document.content, version.content
    assert_equal "Primera", version.summary
    assert_nil version.author
    assert_equal 1, @document.current_content_version_number
  end

  def test_version_number_is_unique_per_record_and_independent_between_records
    other = Document.create!(title: "Otra", author_name: "Ana")

    @document.create_version!(author_name: "Ana")
    other.create_version!(author_name: "Ana")

    assert_equal 1, @document.content_versions.sole.version_number
    assert_equal 1, other.content_versions.sole.version_number

    assert_raises ActiveRecord::RecordInvalid do
      Bali::ContentVersion.create!(record: @document, version_number: 1, author_name: "Ana")
    end
  end

  # El caso que justifica el coalescing: una ráfaga de autosaves es UNA versión.
  def test_coalesce_updates_the_last_version_for_the_same_author_inside_the_window
    first = @document.create_or_coalesce_version!(author_name: "Ana")

    @document.update!(content: [ { "type" => "paragraph", "id" => "b" } ])
    travel 2.minutes do
      second = @document.create_or_coalesce_version!(author_name: "Ana")

      assert_equal first.id, second.id
      assert_equal 1, @document.content_versions.count
      assert_equal @document.content, second.reload.content
    end
  end

  def test_coalesce_creates_a_new_version_past_the_window
    @document.create_or_coalesce_version!(author_name: "Ana")

    travel 6.minutes do
      @document.create_or_coalesce_version!(author_name: "Ana")
    end

    assert_equal 2, @document.content_versions.count
    assert_equal [ 1, 2 ], @document.content_versions.pluck(:version_number)
  end

  def test_coalesce_creates_a_new_version_for_a_different_author_name
    @document.create_or_coalesce_version!(author_name: "Ana")
    @document.create_or_coalesce_version!(author_name: "Beto")

    assert_equal 2, @document.content_versions.count
    assert_equal %w[Ana Beto], @document.content_versions.pluck(:author_name)
  end

  # La decisión 707-1: con FK presente la comparación es por (author_type, author_id), no
  # por el nombre denormalizado — dos usuarios homónimos no colapsan en una sola versión.
  def test_coalesce_compares_by_author_record_when_there_is_one
    @document.create_or_coalesce_version!(author: @ana, author_name: "Ana")
    @document.create_or_coalesce_version!(author: @beto, author_name: "Ana")

    assert_equal 2, @document.content_versions.count
    assert_equal [ @ana, @beto ], @document.content_versions.map(&:author)
  end

  def test_coalesce_treats_the_same_author_record_as_the_same_author
    first = @document.create_or_coalesce_version!(author: @ana, author_name: "Ana")
    second = @document.create_or_coalesce_version!(author: @ana, author_name: "Ana García")

    assert_equal first.id, second.id
  end

  # Un autosave no manda summary; asignar nil borraría el nombre que la versión ya tenía.
  def test_coalesce_keeps_the_previous_summary_when_none_is_given
    @document.create_or_coalesce_version!(author_name: "Ana", summary: "Borrador inicial")
    @document.create_or_coalesce_version!(author_name: "Ana")

    assert_equal "Borrador inicial", @document.content_versions.sole.summary
  end

  # Dos autosaves concurrentes leían la misma "última versión" y creaban dos filas con el
  # mismo version_number: la lectura y la escritura tienen que ir bajo el mismo lock de
  # fila. Se afirma que el lock se toma en vez de correr hilos porque el dummy usa sqlite,
  # que ignora `FOR UPDATE` — una carrera aquí probaría el adapter, no el código, y sería
  # flaky en ambas direcciones. El índice único de la migración es la red debajo, y el test
  # de arriba lo cubre.
  def test_coalescing_reads_and_writes_under_a_row_lock
    locked_during_call = false
    @document.define_singleton_method(:with_lock) do |&block|
      locked_during_call = true
      super(&block)
    end

    @document.create_or_coalesce_version!(author_name: "Ana")

    assert locked_during_call, "create_or_coalesce_version! debe correr dentro de with_lock"
  end

  def test_content_at_version_returns_the_snapshot_of_that_number
    @document.create_version!(author_name: "Ana")
    @document.update!(content: [ { "type" => "paragraph", "id" => "b" } ])
    @document.create_version!(author_name: "Ana")

    assert_equal [ { "type" => "paragraph", "id" => "a" } ], @document.content_at_version(1)
    assert_equal [ { "type" => "paragraph", "id" => "b" } ], @document.content_at_version(2)
    assert_nil @document.content_at_version(99)
  end

  def test_restore_puts_the_content_back_and_records_a_version_naming_the_origin
    original = @document.content
    @document.create_version!(author_name: "Ana", summary: "Primera")
    @document.update!(content: [ { "type" => "paragraph", "id" => "b" } ])
    @document.create_version!(author_name: "Ana")

    @document.restore_content_version!(@document.content_versions.first,
                                       author: @beto, author_name: "Beto")

    assert_equal original, @document.reload.content
    restored = @document.content_versions.last
    assert_equal 3, restored.version_number
    assert_equal original, restored.content
    assert_equal "Restored from v1", restored.summary
    assert_equal @beto, restored.author
  end

  def test_restore_accepts_a_version_id
    @document.create_version!(author_name: "Ana")
    @document.update!(content: [])

    @document.restore_content_version!(@document.content_versions.first.id, author_name: "Ana")

    assert_equal [ { "type" => "paragraph", "id" => "a" } ], @document.reload.content
  end

  def test_destroying_the_record_destroys_its_versions_once
    @document.create_version!(author_name: "Ana")

    assert_difference "Bali::ContentVersion.count", -1 do
      @document.destroy!
    end
  end

  # La versión puede llevar un archivo adjunto (el content_kind "file" de gc), pero NO lo
  # exige: ActiveStorage sigue siendo opcional en el engine.
  def test_a_version_can_carry_a_file_without_requiring_one
    version = @document.create_version!(author_name: "Ana")

    assert_predicate version, :valid?
    refute_predicate version.file, :attached?

    version.file.attach(io: StringIO.new("acta"), filename: "acta.txt", content_type: "text/plain")

    assert_predicate version.reload.file, :attached?
  end

  def test_the_macro_configures_the_attribute_and_the_window
    assert_equal :content, Document.content_version_attribute
    assert_equal 5.minutes, Document.content_version_coalesce_window
  end
end
