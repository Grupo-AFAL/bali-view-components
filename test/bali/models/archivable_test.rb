# frozen_string_literal: true

require "test_helper"

# #721 — archiving a host record. The dummy's Movie adopts the concern, so these tests exercise the
# adoption a host is asked for.
class BaliArchivableTest < ActiveSupport::TestCase
  include ArchivableDeclaration

  def setup
    studio = Tenant.create!(name: "Studio")
    @movie = studio.movies.create!(name: "Blade Runner", status: 0)
    @remake = studio.movies.create!(name: "Blade Runner 2049", status: 0)
    @ana = User.create!(name: "Ana")
  end

  def test_archive_records_who_why_and_what_replaces_it
    archival = @movie.archive!(by: @ana, reason: :replaced, note: "Remastered", successor: @remake)

    assert @movie.archived?
    assert_equal archival, @movie.archival
    assert_equal [ @ana, "replaced", "Remastered", @remake ],
                 [ archival.archived_by, archival.reason, archival.note, archival.successor ]
  end

  # The second call is invalid on its own (`misfiled` is not a reason): without the guard it
  # would raise RecordInvalid, so the redirect for "already archived" comes before validation.
  def test_archiving_twice_raises_already_archived
    @movie.archive!(by: @ana)

    assert_raises(Bali::Archivable::AlreadyArchived) { @movie.archive!(by: @ana, reason: :misfiled) }
    assert_equal 1, @movie.archivals.count
  end

  # Two requests that both read "not archived" before either writes.
  def test_a_concurrent_archival_raises_already_archived
    stale = Movie.find(@movie.id)
    refute stale.archived?
    @movie.archive!(by: @ana)

    assert_raises(Bali::Archivable::AlreadyArchived) { stale.archive!(by: @ana) }
    assert_equal 1, @movie.archivals.count
  end

  # Two requests that both read the current archival before either reopens it.
  def test_a_concurrent_reopening_raises_not_archived
    stale = Movie.find(@movie.id)
    @movie.archive!(by: @ana)
    assert stale.archived?
    @movie.unarchive!(by: @ana)

    assert_raises(Bali::Archivable::NotArchived) { stale.unarchive!(by: User.create!(name: "Luis")) }
    assert_equal @ana, @movie.archivals.first.unarchived_by
  end

  def test_a_reason_outside_the_models_list_is_invalid
    error = assert_raises(ActiveRecord::RecordInvalid) { @movie.archive!(reason: :misfiled) }

    assert_includes error.record.errors.attribute_names, :reason
    refute @movie.archived?
  end

  def test_a_reason_that_needs_a_successor_is_invalid_without_one
    error = assert_raises(ActiveRecord::RecordInvalid) { @movie.archive!(reason: :replaced) }

    assert_includes error.record.errors.attribute_names, :successor_id
  end

  def test_a_record_cannot_succeed_itself
    error = assert_raises(ActiveRecord::RecordInvalid) do
      @movie.archive!(reason: :replaced, successor: @movie)
    end

    assert_includes error.record.errors.attribute_names, :successor_id
  end

  def test_the_note_is_at_most_500_characters
    error = assert_raises(ActiveRecord::RecordInvalid) { @movie.archive!(note: "a" * 501) }

    assert_includes error.record.errors.attribute_names, :note
    assert_predicate @remake.archive!(note: "a" * 500), :persisted?
  end

  def test_unarchive_on_an_irreversible_model_raises_not_reversible
    @movie.archive!(by: @ana)

    with_archivable(successor_required_for: %i[replaced]) do
      assert_raises(Bali::Archivable::NotReversible) { @movie.unarchive!(by: @ana) }
    end
    assert @movie.reload.archived?
  end

  def test_unarchive_without_a_current_archival_raises_not_archived
    assert_raises(Bali::Archivable::NotArchived) { @movie.unarchive!(by: @ana) }
  end

  def test_reopening_keeps_the_archival_as_history
    first = @movie.archive!(by: @ana, reason: :expired)
    @movie.unarchive!(by: @ana)

    refute @movie.archived?
    assert_equal @ana, first.reload.unarchived_by
    assert_not_nil first.unarchived_at

    travel 1.minute
    second = @movie.archive!(by: @ana, reason: :other)
    assert_equal [ second, first ], @movie.archivals.to_a
  end

  # Reopening is not a new decision: a reason the model retired since must not block it.
  def test_reopening_an_archival_whose_reason_was_retired
    @movie.archive!(by: @ana, reason: :expired)

    with_archivable(reasons: %w[other], reversible: true) do
      assert_nothing_raised { @movie.unarchive!(by: @ana) }
    end
  end

  def test_scopes_split_records_by_their_current_archival
    reopened = @movie.studio.movies.create!(name: "Alien", status: 0)
    @movie.archive!(by: @ana)
    reopened.archive!(by: @ana)
    reopened.unarchive!(by: @ana)

    assert_equal [ @movie.id ], Movie.archived.ids
    assert_equal [ @remake.id, reopened.id ].sort, Movie.not_archived.ids.sort
  end

  def test_scopes_chain_with_other_conditions
    @movie.archive!(by: @ana)

    assert_equal [ @movie.id ], Movie.where("name LIKE ?", "Blade Runner%").archived.ids
    assert_equal [ @remake.id ], Movie.where("name LIKE ?", "Blade Runner%").not_archived.ids
  end

  def test_the_database_refuses_two_current_archivals
    Bali::Archival.create!(archivable: @movie)

    assert_raises(ActiveRecord::RecordNotUnique) { Bali::Archival.create!(archivable: @movie) }
  end

  def test_reason_label_reads_the_models_own_key_before_balis
    archival = @movie.archive!(reason: :expired)
    assert_equal "Expired", archival.reason_label

    I18n.backend.store_translations(:en, activerecord: { archival_reasons: { movie: { expired: "Out of rights" } } })
    assert_equal "Out of rights", archival.reason_label
  ensure
    I18n.backend.reload!
  end

  # Hosts run with `raise_on_missing_translations`: a reason only the model labels must not
  # make the lookup of Bali's own key raise.
  def test_reason_label_of_a_custom_reason_raises_nothing_when_missing_translations_raise
    handler = I18n.exception_handler
    I18n.exception_handler = ->(exception, *) { raise exception }
    I18n.backend.store_translations(:en, activerecord: { archival_reasons: { movie: { revoked: "Revoked by board" } } })

    with_archivable(reasons: %w[revoked]) do
      assert_equal "Revoked by board", @movie.archive!(reason: :revoked).reason_label
    end
  ensure
    I18n.exception_handler = handler
    I18n.backend.reload!
  end

  def test_the_macro_with_no_arguments_takes_every_default
    with_archivable do
      assert_equal Bali::Archivable::DEFAULT_REASONS, Movie.archival_reasons
      assert_empty Movie.archival_successor_required_for
      refute Movie.archival_reversible
    end
  end

  def test_local_path_keeps_only_paths_on_this_origin
    assert_equal "/admin/movies?page=2", Bali::Archival.local_path("/admin/movies?page=2")
    [ "//evil.example", "/\\evil.example", "https://evil.example", "javascript:alert(1)", "/\t/evil.example", "/\n/evil.example", "/ /evil.example", "", nil ].each do |value|
      assert_nil Bali::Archival.local_path(value), value.inspect
    end
  end

  def test_name_of_prefers_title_then_name
    assert_equal "Acta", Bali::Archival.name_of(Document.new(title: "Acta", author_name: "Ana"))
    assert_equal "Blade Runner", Bali::Archival.name_of(@movie)
    assert_equal "Ana", Bali::Archival.name_of(@ana)
  end

  def test_include_alone_takes_every_default
    model = Class.new(ApplicationRecord) do
      self.table_name = "movies"
      include Bali::Archivable
    end

    assert_equal Bali::Archivable::DEFAULT_REASONS, model.archival_reasons
    assert_empty model.archival_successor_required_for
    refute model.archival_reversible
  end
end
