# frozen_string_literal: true

require "test_helper"

# #707 — the history the engine lends a host's model. `Document` (from the dummy) includes the
# concern, so these tests exercise exactly the adoption a real app is asked for.
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

  # The case that justifies the coalescing: a burst of autosaves is ONE version.
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

  # Decision 707-1: with the FK present the comparison is by (author_type, author_id), not by the
  # denormalised name — two users of the same name do not collapse into a single version.
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

  # An autosave sends no summary; assigning nil would wipe the name the version already had.
  def test_coalesce_keeps_the_previous_summary_when_none_is_given
    @document.create_or_coalesce_version!(author_name: "Ana", summary: "Borrador inicial")
    @document.create_or_coalesce_version!(author_name: "Ana")

    assert_equal "Borrador inicial", @document.content_versions.sole.summary
  end

  # Two concurrent autosaves read the same "last version" and created two rows with the same
  # version_number: the read and the write have to go under the same row lock. The assertion is that
  # the lock is taken rather than running threads, because the dummy is on sqlite, which ignores
  # `FOR UPDATE` — a race here would test the adapter, not the code, and would be flaky in both
  # directions. The migration's unique index is the net underneath, and the test above covers it.
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

  # Security review finding (MEDIUM-1): passing an OBJECT was accepted as is, with no check of whose
  # it was, so any other record's version content could be copied over this one. It is now re-scoped
  # through that path too.
  def test_restore_refuses_a_version_object_belonging_to_another_record
    other = Document.create!(title: "Ajena", author_name: "Beto",
                             content: [ { "type" => "paragraph", "id" => "secreto" } ])
    foreign_version = other.create_version!(author_name: "Beto")

    assert_raises ActiveRecord::RecordNotFound do
      @document.restore_content_version!(foreign_version, author_name: "Ana")
    end

    assert_equal [ { "type" => "paragraph", "id" => "a" } ], @document.reload.content
    assert_empty @document.content_versions
  end

  def test_restore_refuses_a_version_id_belonging_to_another_record
    other = Document.create!(title: "Ajena", author_name: "Beto")
    foreign_version = other.create_version!(author_name: "Beto")

    assert_raises ActiveRecord::RecordNotFound do
      @document.restore_content_version!(foreign_version.id, author_name: "Ana")
    end
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

  # A version can carry an attached file (gc's "file" content_kind), but it does NOT require one:
  # ActiveStorage stays optional in the engine.
  def test_a_version_can_carry_a_file_without_requiring_one
    version = @document.create_version!(author_name: "Ana")

    assert_predicate version, :valid?
    refute_predicate version.file, :attached?

    version.file.attach(io: StringIO.new("acta"), filename: "acta.txt", content_type: "text/plain")

    assert_predicate version.reload.file, :attached?
  end

  # Security review finding (LOW-6): `create_version!` had the same race as the coalescing, between
  # reading the highest number and writing the next one.
  def test_create_version_reads_and_writes_under_a_row_lock
    locked = false
    @document.define_singleton_method(:with_lock) do |&block|
      locked = true
      super(&block)
    end

    @document.create_version!(author_name: "Ana")

    assert locked, "create_version! debe correr dentro de with_lock"
  end

  # A consequence of the lock, and the best one available: versioning with unsaved changes fails
  # LOUDLY. Rails refuses to lock a dirty record, so instead of silently deciding between the value
  # in memory and the stored one —a version claiming content the database never saw is false— the
  # caller finds out and saves first. `create_or_coalesce_version!` already behaved this way; now the
  # two agree.
  def test_versioning_a_record_with_unsaved_changes_fails_loudly
    @document.content = [ { "type" => "paragraph", "id" => "sin-guardar" } ]

    error = assert_raises RuntimeError do
      @document.create_version!(author_name: "Ana")
    end

    assert_match(/unpersisted changes/, error.message)
    assert_empty @document.content_versions
  end

  # Belt and braces from the review: the model rejects the over-long summary with an error the host
  # can show, and the column holds it underneath.
  def test_a_summary_longer_than_the_limit_is_rejected_by_the_model
    error = assert_raises ActiveRecord::RecordInvalid do
      @document.create_version!(author_name: "Ana", summary: "x" * 256)
    end

    assert_match(/summary/i, error.message)
    assert_nothing_raised do
      @document.create_version!(author_name: "Ana", summary: "x" * 255)
    end
  end

  def test_the_macro_configures_the_attribute_and_the_window
    assert_equal :content, Document.content_version_attribute
    assert_equal 5.minutes, Document.content_version_coalesce_window
  end
end
