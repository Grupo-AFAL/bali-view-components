# frozen_string_literal: true

require "test_helper"

# #1156, half 1. A grouping default lives INSIDE the form and never travels by URL, unlike
# `filter_attribute default:`: `redirect_to_default_filters` turns itself off entirely where
# filter persistence is on (filterable.rb:104), and a redirect writing `?group_by=` would mark
# the param as REQUESTED, overwriting in the cache the "no grouping" the user chose.
#
#   URL > saved view payload > choice stored in the cache > `default:` > no grouping
class BaliFilterFormDefaultGroupByTest < ActiveSupport::TestCase
  class DefaultGroupedMovieFilterForm < Bali::FilterForm
    group_by_attribute :genre, label: "Genre"
    group_by_attribute :status, default: true

    attribute :genre_eq
  end

  def group_params(**extra)
    ActionController::Parameters.new({ q: ActionController::Parameters.new({}) }.merge(extra))
  end

  def form(**extra)
    DefaultGroupedMovieFilterForm.new(Movie.all, group_params(**extra))
  end

  # --- The default applies when nobody said anything ---

  def test_the_declared_default_groups_the_listing_when_no_param_arrives
    opened = form

    assert_equal(:status, opened.group_by)
    assert_equal(:status, opened.group_by_applied)
    assert(opened.group_by_active?)
  end

  def test_the_default_is_readable_as_such
    assert_equal(:status, DefaultGroupedMovieFilterForm.new(Movie.all, group_params).default_group_by)
    assert(form.group_by_from_default?)
    refute(form(group_by: "status").group_by_from_default?,
           "picking the same value the default has is a CHOICE, not a default")
  end

  # --- The URL always wins ---

  def test_an_explicit_group_by_in_the_url_beats_the_default
    assert_equal(:genre, form(group_by: "genre").group_by)
    refute(form(group_by: "genre").group_by_from_default?)
  end

  # Without this the user cannot ungroup a listing that declares a default.
  def test_an_empty_group_by_in_the_url_turns_the_grouping_off
    ungrouped = form(group_by: "")

    assert_nil(ungrouped.group_by)
    refute(ungrouped.group_by_active?)
  end

  def test_an_undeclared_group_by_value_also_counts_as_the_url_speaking
    assert_nil(form(group_by: "none").group_by)
  end

  # An empty param does not survive Ransack's `sort_link` nor the hidden fields: measured with
  # the server up, `?group_by=` disappears from the sort href and `?group_by=genre` does not.
  def test_no_grouping_travels_by_name_only_where_a_default_needs_it
    assert_equal("none", form.no_grouping_value)
    assert_equal("", Bali::FilterForm.new(Movie.all, group_params,
                                          group_by_attributes: %i[genre status]).no_grouping_value)
  end

  def test_the_named_no_grouping_value_survives_a_round_trip
    assert_nil(form(group_by: Bali::FilterForm::GroupByConfiguration::NO_GROUPING_VALUE).group_by)
  end

  # --- Suspension: a default is state like any other ---

  def test_the_default_is_suspended_outside_a_grouping_mode
    suspended = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params, group_by_modes: [ :table ], display_mode: :grid
    )

    assert_equal(:status, suspended.group_by)
    assert_nil(suspended.group_by_applied)
    assert(suspended.group_by_suspended?)
  end

  # In grid mode the grouping is neither applied nor visible, but "no grouping" has to keep
  # travelling or coming back to the table regroups the listing with the default.
  def test_an_explicit_no_grouping_keeps_travelling_while_suspended
    suspended = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(group_by: "none"), group_by_modes: [ :table ], display_mode: :grid
    )

    assert_nil(suspended.group_by)
    assert_equal("none", suspended.group_by_preserved_value)
  end

  def test_what_travels_has_three_answers_and_not_two
    assert_nil(form.group_by_preserved_value, "a default re-derives itself: carrying it makes it a choice")
    assert_equal("genre", form(group_by: "genre").group_by_preserved_value)
    assert_equal("none", form(group_by: "none").group_by_preserved_value)
  end

  # --- Declaration ---

  def test_the_constructor_form_accepts_the_default_too
    instance = Bali::FilterForm.new(
      Movie.all, group_params,
      group_by_attributes: [ :genre, { attribute: :status, default: true } ]
    )

    assert_equal(:status, instance.group_by)
  end

  def test_two_different_defaults_raise_when_the_form_is_built
    contradiction = Class.new(Bali::FilterForm) do
      group_by_attribute :genre, default: true
      group_by_attribute :status, default: true
    end

    error = assert_raises(ArgumentError) { contradiction.new(Movie.all, group_params) }
    assert_match(/genre/, error.message)
    assert_match(/status/, error.message)
  end

  def test_a_callable_default_raises_instead_of_being_silently_truthy
    callable = Class.new(Bali::FilterForm) do
      group_by_attribute :status, default: -> { true }
    end

    error = assert_raises(ArgumentError) { callable.new(Movie.all, group_params) }
    assert_match(/default:/, error.message)
  end

  def test_a_subclass_inherits_the_declared_default
    subclass = Class.new(DefaultGroupedMovieFilterForm)

    assert_equal(:status, subclass.new(Movie.all, group_params).group_by)
  end

  # --- Saved views ---

  class FakeSavedViewsStore
    SavedView = Struct.new(:id, :name, :payload, keyword_init: true)

    def initialize(views = []) = @views = views
    def list = @views
    def find(id) = @views.find { |view| view.id.to_s == id.to_s }
    def save(name:, payload:) = SavedView.new(id: 1, name: name, payload: payload)
    def delete(id) = @views.reject! { |view| view.id.to_s == id.to_s }
  end

  def store_with_view(payload)
    FakeSavedViewsStore.new([ FakeSavedViewsStore::SavedView.new(id: 1, name: "My view", payload: payload) ])
  end

  def test_a_saved_view_that_records_a_grouping_beats_the_default
    applied = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(saved_view: "1"),
      saved_views_store: store_with_view({ "group_by" => "genre" })
    )

    assert_equal(:genre, applied.group_by)
    refute(applied.group_by_from_default?)
  end

  # If it entered, EVERY saved view without `group_by` would read as "modified" against a
  # listing nobody touched (see `comparable_view_state`).
  def test_a_default_only_grouping_stays_out_of_the_saved_view_payload
    payload = form.current_view_payload

    refute(payload.key?("group_by"), payload.inspect)
    assert_equal("status", form(group_by: "status").current_view_payload["group_by"])
  end

  # The round trip that was missing: a view saved while the user had the grouping OFF reopened
  # GROUPED, because the nil was compacted out of the payload and the default found nobody who
  # had spoken. The view has to be able to SAY "ungrouped".
  def test_a_view_saved_while_ungrouped_reopens_ungrouped
    payload = form(group_by: Bali::FilterForm::GroupByConfiguration::NO_GROUPING_VALUE)
              .current_view_payload

    assert_equal("none", payload["group_by"], payload.inspect)

    reopened = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(saved_view: "1"), saved_views_store: store_with_view(payload)
    )

    assert_nil(reopened.group_by, "the view said ungrouped: the default cannot resurrect it")
    refute(reopened.group_by_from_default?)
  end

  # Why silence cannot mean "no grouping": a view saved before the default existed arrives
  # WITHOUT the key, and there the default is still the one speaking.
  def test_a_view_that_says_nothing_about_grouping_still_takes_the_default
    applied = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(saved_view: "1"),
      saved_views_store: store_with_view({ "attributes" => { "genre_eq" => "Action" } })
    )

    assert_equal(:status, applied.group_by)
    assert(applied.group_by_from_default?)
  end

  def test_an_ungrouped_view_is_recognised_as_active_when_reopened
    payload = form(group_by: "none").current_view_payload
    view = FakeSavedViewsStore::SavedView.new(id: 1, name: "Ungrouped", payload: payload)
    reopened = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(saved_view: "1"), saved_views_store: FakeSavedViewsStore.new([ view ])
    )

    assert(reopened.view_matches_current_state?(view))
  end

  # With no default there is nothing to suppress, so the payload does not change one byte.
  def test_a_listing_without_a_default_keeps_the_payload_it_always_had
    plain = Bali::FilterForm.new(Movie.all, group_params(group_by: ""),
                                 group_by_attributes: %i[genre status])

    refute(plain.current_view_payload.key?("group_by"), plain.current_view_payload.inspect)
  end

  def test_a_view_saved_under_the_default_is_still_recognised_as_active
    view = FakeSavedViewsStore::SavedView.new(id: 1, name: "My view",
                                              payload: { "attributes" => { "genre_eq" => "Action" } })
    applied = DefaultGroupedMovieFilterForm.new(
      Movie.all, group_params(q: ActionController::Parameters.new(genre_eq: "Action")),
      saved_views_store: FakeSavedViewsStore.new([ view ])
    )

    assert(applied.view_matches_current_state?(view))
  end
end

class BaliFilterFormDefaultGroupByPersistenceTest < ActiveSupport::TestCase
  class PersistedDefaultGroupedFilterForm < Bali::FilterForm
    group_by_attribute :genre
    group_by_attribute :status, default: true

    attribute :genre_eq
  end

  def setup
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear
  end

  def teardown
    Rails.cache = @original_cache
  end

  def cache_key
    "#{PersistedDefaultGroupedFilterForm.name.tableize};;movies"
  end

  def persisted_form(**extra)
    PersistedDefaultGroupedFilterForm.new(
      Movie.all, ActionController::Parameters.new(extra),
      storage_id: "movies", persist_enabled: true
    )
  end

  def test_a_grouping_stored_in_the_cache_beats_the_default
    Rails.cache.write(cache_key, { attributes: {}, group_by: "genre", group_by_chosen: true })

    assert_equal(:genre, persisted_form.group_by)
  end

  def test_an_explicit_no_grouping_stored_in_the_cache_is_not_resurrected_by_the_default
    PersistedDefaultGroupedFilterForm.new(
      Movie.all, ActionController::Parameters.new(group_by: ""),
      storage_id: "movies", persist_enabled: true
    )

    assert_nil(persisted_form.group_by, "the user ungrouped: the default cannot resurrect it")
  end

  # v3.4.0 writes `group_by: nil` on EVERY filter submit (filter_form.rb:688), so any listing
  # with persistence already has that key stored. If the mere presence of the key turned the
  # default off, the feature would be born dead in production.
  def test_a_cache_written_before_the_default_existed_does_not_kill_it
    Rails.cache.write(cache_key, { attributes: { "genre_eq" => "Action" }, group_by: nil })

    assert_equal(:status, persisted_form.group_by)
  end

  # Derived, not persisted: changing the default in code has to change what users who already
  # visited the listing see.
  def test_the_default_is_never_written_into_the_cache
    PersistedDefaultGroupedFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { genre_eq: "Action" }),
      storage_id: "movies"
    )

    stored = Rails.cache.read(cache_key)
    assert_nil(stored[:group_by])
    refute(stored[:group_by_chosen])
  end

  def test_a_chosen_grouping_is_still_written_into_the_cache
    PersistedDefaultGroupedFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { genre_eq: "Action" }, group_by: "genre"),
      storage_id: "movies"
    )

    stored = Rails.cache.read(cache_key)
    assert_equal("genre", stored[:group_by].to_s)
    assert(stored[:group_by_chosen])
  end
end
