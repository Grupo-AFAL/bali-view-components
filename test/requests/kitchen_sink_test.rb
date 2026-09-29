# frozen_string_literal: true

require "test_helper"

class KitchenSinkDemoPagesTest < ActionDispatch::IntegrationTest
  def setup
    @tenant = Tenant.create!(name: "Test Studio")
    @movie = @tenant.movies.create!(name: "Test Movie", status: 0)
  end

  def movie
    @movie
  end

  def test_dashboard_renders_the_dashboard_page_successfully
    get root_path
    assert_response :ok
  end

  # The canonical index has THREE content branches (selectable table, card grid and calendar) sharing
  # one partial. Without asking for them, a null date, a missing i18n key or a broken `with_content`
  # ships green.
  def test_admin_movies_renders_every_display_mode_of_the_canonical_listing
    get admin_movies_path
    assert_response :ok
    assert_select "table.table"

    get admin_movies_path, params: { view: "grid" }
    assert_response :ok
    assert_select "h2.card-title"

    get admin_movies_path, params: { view: "calendar" }
    assert_response :ok
    assert_select ".calendar-component"
  end

  # The reference page has to exercise the WHOLE family of controls: with no owner the store does not
  # resolve and the dropdown disappears without breaking anything.
  def test_admin_movies_renders_the_saved_views_dropdown
    get admin_movies_path
    assert_response :ok
    assert_select "[data-controller~='saved-views']"
  end

  # Ransack drops a combined predicate ENTIRELY when one of its fields is not ransackable, without
  # raising anything: the search answered 200 and returned everything. Hence the assertion is on the
  # SET, not on the status.
  def test_admin_movies_quick_search_narrows_the_result_set
    other = Tenant.create!(name: "Otro Estudio")
    other.movies.create!(name: "Otra Película", status: 0)

    get admin_movies_path, params: { q: { name_or_genre_or_studio_name_cont: "Test Studio" } }
    assert_response :ok
    assert_select "tbody tr", 1
    assert_select "tbody tr", text: /Otra Película/, count: 0
  end

  # Ransack casts with the column's RAW type, so over an integer enum the label "done" became 0 —the
  # code for `draft`— and the filter returned the OPPOSITE records. This is the only test that walks
  # the exact URL shape Bali::Filters' builder emits. The assertion is on the SET: an
  # `assert_response :ok` passed with the bug in place.
  def test_admin_movies_filters_by_an_enum_label_from_the_filters_builder
    done_movie = @tenant.movies.create!(name: "Película Terminada", status: 1)

    get admin_movies_path, params: { q: { g: { "0" => { status_in: [ "done" ], m: "and" } } } }

    assert_response :ok
    assert_select "tbody tr", 1
    assert_select "tbody tr", text: /#{done_movie.name}/
    assert_select "tbody tr", text: /#{@movie.name}/, count: 0
  end

  def test_admin_movies_sorts_by_the_studio_association
    get admin_movies_path, params: { q: { s: "studio_name asc" } }
    assert_response :ok
    assert_select "th[aria-sort='ascending']", text: /Studio/
  end

  def test_admin_movies_groups_rows_when_the_group_by_control_is_used
    get admin_movies_path, params: { group_by: "status" }
    assert_response :ok
    assert_select "tr.bali-table-group-row"
  end

  def test_admin_movies_suspends_grouping_in_grid_mode_without_dropping_the_param
    # The grouping only applies in the table: in cards there is no group band to explain the
    # reordering. The param still has to travel in the filters form, or searching from cards wipes
    # it.
    get admin_movies_path, params: { group_by: "status", view: "grid" }
    assert_response :ok
    assert_select "tr.bali-table-group-row", count: 0
    assert_select "input[name=group_by][value=status]"
  end

  def test_movies_get_movies_id_renders_the_show_page_successfully
    get movie_path(movie)
    assert_response :ok
  end

  def test_movies_get_movies_new_renders_the_new_page_successfully
    get new_movie_path
    assert_response :ok
  end

  def test_movies_get_movies_id_edit_renders_the_edit_page_successfully
    get edit_movie_path(movie)
    assert_response :ok
  end

  def test_settings_get_settings_renders_the_settings_page_successfully
    get settings_path
    assert_response :ok
  end

  def test_landing_page_get_landing_renders_the_landing_page_successfully
    get landing_path
    assert_response :ok
  end
end

# Filter persistence only exists in full through a REQUEST: cookie → `persist_enabled:` → restore →
# rendered listing. Nothing walked it, and no test covered the stretch that switched it off entirely
# (the dummy's cache store).
class KitchenSinkFilterPersistenceTest < ActionDispatch::IntegrationTest
  # The test env runs with `:null_store`, where every write is lost and every read is nil: a
  # persistence test there passes without asserting anything. The store is swapped ONLY here —
  # coupling the whole suite to a global cache is exactly what this exists not to do.
  def setup
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    @tenant = Tenant.create!(name: "Test Studio")
    @draft = @tenant.movies.create!(name: "Película Borrador", status: 0)
    @done = @tenant.movies.create!(name: "Película Terminada", status: 1)
  end

  def teardown
    Rails.cache = @original_cache
  end

  def filtered_params
    { q: { g: { "0" => { status_in: [ "done" ], m: "and" } } } }
  end

  def test_the_listing_restores_the_filters_of_the_previous_visit
    cookies["bali_persist_admin_movies"] = "1"
    get admin_movies_path, params: filtered_params
    assert_select "tbody tr", 1

    get admin_movies_path
    assert_response :ok
    assert_select "tbody tr", 1
    assert_select "tbody tr", text: /#{@done.name}/
  end

  # The cache is keyed `class;context;storage_id`: without `context:` a single key serves EVERY visit
  # in the process and one visitor's filters are restored to the next. With `:null_store` this was
  # invisible, because nothing was stored.
  def test_a_visitor_does_not_restore_another_visitors_filters
    filtering = open_session
    filtering.cookies["bali_persist_admin_movies"] = "1"
    filtering.get admin_movies_path, params: filtered_params
    assert_not_includes filtering.response.body, @draft.name

    arriving = open_session
    arriving.cookies["bali_persist_admin_movies"] = "1"
    arriving.get admin_movies_path

    assert_includes arriving.response.body, @draft.name
    assert_includes arriving.response.body, @done.name
  end
end
