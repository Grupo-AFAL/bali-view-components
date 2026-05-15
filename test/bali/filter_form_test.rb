# frozen_string_literal: true

require "test_helper"

class MovieFilterForm < Bali::FilterForm
  attribute :name_i_cont, :string
  attribute :genre_in, default: []

  def scope
    @scope.draft.order("UPPER(name) ASC")
  end
end

# Test form with filter_attribute DSL
class AdvancedMovieFilterForm < Bali::FilterForm
  filter_attribute :name, type: :text
  filter_attribute :genre, type: :select, options: [ %w[Action action], %w[Comedy comedy] ]
  filter_attribute :status, type: :select, label: "Movie Status"
  filter_attribute :created_at, type: :date, label: "Created Date"
  filter_attribute :indie, type: :boolean

  attribute :name_cont
  attribute :genre_eq
end

# Test inheritance
class ExtendedMovieFilterForm < AdvancedMovieFilterForm
  filter_attribute :rating, type: :number
end

# Test form with search_fields DSL
class SearchableMovieFilterForm < Bali::FilterForm
  search_fields :name, :genre, :tenant_name

  filter_attribute :name, type: :text
  filter_attribute :genre, type: :select, options: [ %w[Action action], %w[Comedy comedy] ]
end

# Test form with simple_filter DSL
class SimpleFilterableMovieFilterForm < Bali::FilterForm
  simple_filter :genre,
                collection: [ %w[Action action], %w[Comedy comedy], %w[Drama drama] ],
                blank: "All Genres"

  simple_filter :status,
                collection: [ %w[Done done], %w[Draft draft] ],
                blank: "All",
                label: "Movie Status",
                default: "done"
end

# Test simple_filter inheritance
class ExtendedSimpleFilterForm < SimpleFilterableMovieFilterForm
  simple_filter :indie,
                collection: [ [ true, true ], [ false, false ] ],
                blank: "Any",
                label: "Indie Film"
end

class BaliFilterFormTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create(name: "Test")
    @iron_man_3 = @tenant.movies.create(name: "Iron man 3", status: 1)
    @iron_man_2 = @tenant.movies.create(name: "Iron man 2", status: 0)
    @iron_man_1 = @tenant.movies.create(name: "Iron man 1", status: 0)
    @snatch = @tenant.movies.create(name: "Snatch", status: 0)
    @inglorious_basterds = @tenant.movies.create(name: "Inglorious Basterds", status: 0)
    @form = MovieFilterForm.new(@tenant.movies, params({ name_i_cont: "Iron" }))
    @records = @form.result.to_a
    Rails.cache.clear
  end

  def params(filter_attributes)
    ActionController::Parameters.new(q: filter_attributes)
  end

  def test_initialize_initializes_a_form_with_provided_attributes
    assert_equal("Iron", @form.name_i_cont)
  end

  def test_permitted_attributes_returns_an_array_of_permitted_attributes
    assert_equal([ "s", "name_i_cont", { "genre_in" => [] } ], @form.permitted_attributes)
  end

  def test_array_attributes_returns_an_array_of_array_attributes
    assert_equal([ "genre_in" ], @form.array_attributes)
  end

  def test_active_filters_count_returns_the_number_of_active_filters
    @form = MovieFilterForm.new(@tenant.movies, params({ genre_in: [ "Action" ] }))
    assert_equal(1, @form.active_filters_count)
  end

  def test_active_filters_returns_true_with_movie_name_filter
    @form = MovieFilterForm.new(@tenant.movies, params({ name_i_cont: "Iron" }))
    assert(@form.active_filters?)
  end

  def test_active_filters_returns_true_with_movie_genre_filter
    @form = MovieFilterForm.new(@tenant.movies, params({ genre_in: [ "Action" ] }))
    assert(@form.active_filters?)
  end

  def test_active_filters_returns_false_without_any_filters
    @form = MovieFilterForm.new(@tenant.movies, params({}))
    refute(@form.active_filters?)
  end

  def test_query_params_returns_a_hash_of_attributes_and_values
    assert_equal({ "genre_in" => nil, "name_i_cont" => "Iron", "s" => nil }, @form.query_params)
  end

  def test_result_returns_records_matching_the_query_and_default_scope
    assert_equal(2, @records.size)
    assert_includes(@records.map(&:name), "Iron man 1", "Iron man 2")
  end

  def test_result_orders_results_based_on_the_scope_order
    assert_equal(@iron_man_1, @records.first)
    assert_equal(@iron_man_2, @records.last)
  end

  def test_filter_attribute_dsl_stores_filter_attributes_defined_in_the_class
    assert_equal(5, AdvancedMovieFilterForm.filter_attributes.size)
  end

  def test_filter_attribute_dsl_stores_key_type_label_and_options
    genre_attr = AdvancedMovieFilterForm.filter_attributes.find { |a| a[:key] == :genre }
    assert_equal(:select, genre_attr[:type])
    assert_equal("Genre", genre_attr[:label])
    assert_equal([ %w[Action action], %w[Comedy comedy] ], genre_attr[:options])
  end

  def test_filter_attribute_dsl_uses_humanized_key_as_default_label
    name_attr = AdvancedMovieFilterForm.filter_attributes.find { |a| a[:key] == :name }
    assert_equal("Name", name_attr[:label])
  end

  def test_filter_attribute_dsl_allows_custom_labels
    status_attr = AdvancedMovieFilterForm.filter_attributes.find { |a| a[:key] == :status }
    assert_equal("Movie Status", status_attr[:label])
  end

  def test_filter_attribute_inheritance_inherits_filter_attributes_from_parent_class
    assert_equal(6, ExtendedMovieFilterForm.filter_attributes.size)
  end

  def test_filter_attribute_inheritance_includes_parent_attributes
    keys = ExtendedMovieFilterForm.filter_attributes.pluck(:key)
    assert_includes(keys, :name)
    assert_includes(keys, :genre)
    assert_includes(keys, :status)
    assert_includes(keys, :created_at)
    assert_includes(keys, :indie)
    assert_includes(keys, :rating)
  end

  def test_filter_attribute_inheritance_does_not_modify_parent_class_attributes
    assert_equal(5, AdvancedMovieFilterForm.filter_attributes.size)
  end

  def test_available_attributes_returns_the_filter_attributes_from_the_class
    @form = AdvancedMovieFilterForm.new(Movie.all, params({}))
    assert_equal(AdvancedMovieFilterForm.filter_attributes, @form.available_attributes)
  end

  def test_available_attributes_returns_empty_array_for_forms_without_filter_attribute_definitions
    @form = MovieFilterForm.new(@tenant.movies, params({}))
    assert_equal([], @form.available_attributes)
  end

  def test_filter_groups_returns_empty_array_when_no_groupings_present
    @form = AdvancedMovieFilterForm.new(Movie.all, params({}))
    assert_equal([], @form.filter_groups)
  end

  def test_filter_groups_parses_single_filter_group_from_params
    filter_params = { g: {
    "0" => { name_cont: "Iron", m: "or"
    }
    }
    }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    groups = @form.filter_groups
    assert_equal(1, groups.size)
    assert_equal("or", groups[0][:combinator])
    assert_equal(1, groups[0][:conditions].size)
    assert_equal({ attribute: "name", operator: "cont", value: "Iron" }, groups[0][:conditions][0])
  end

  def test_filter_groups_parses_multiple_conditions_in_a_group
    filter_params = { g: {
    "0" => { name_cont: "Iron", genre_eq: "action", m: "and"
    }
    }
    }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    conditions = @form.filter_groups[0][:conditions]
    assert_equal(2, conditions.size)
    assert_equal(%w[genre name], conditions.pluck(:attribute).sort)
  end

  def test_filter_groups_consolidates_gteq_and_lteq_into_between_operator
    filter_params = { g: {
    "0" => { created_at_gteq: "2024-01-01", created_at_lteq: "2024-12-31"
    }
    }
    }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    conditions = @form.filter_groups[0][:conditions]
    assert_equal(1, conditions.size)
    assert_equal("between", conditions[0][:operator])
    assert_equal({ start: "2024-01-01", end: "2024-12-31" }, conditions[0][:value])
  end

  def test_filter_groups_parses_multiple_filter_groups
    filter_params = { g: {
    "0" => { name_cont: "Iron", m: "or" }, "1" => { genre_eq: "action", m: "and" }
    }, m: "and"
    }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    assert_equal(2, @form.filter_groups.size)
  end

  def test_combinator_returns_and_as_default
    @form = AdvancedMovieFilterForm.new(Movie.all, params({}))
    assert_equal("and", @form.combinator)
  end

  def test_combinator_returns_combinator_from_params
    filter_params = { m: "or" }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    assert_equal("or", @form.combinator)
  end

  def test_active_filter_details_returns_empty_array_when_no_filters_active
    @form = AdvancedMovieFilterForm.new(Movie.all, params({}))
    assert_equal([], @form.active_filter_details)
  end

  def test_active_filter_details_returns_details_for_each_active_filter
    filter_params = { g: {
    "0" => { name_cont: "Iron", genre_eq: "action"
    }
    }
    }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    details = @form.active_filter_details
    assert_equal(2, details.size)
  end

  def test_active_filter_details_includes_attribute_labels_from_filter_attribute_definitions
    filter_params = { g: {
    "0" => { name_cont: "Iron" }
    }
    }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    detail = @form.active_filter_details.first
    assert_equal("Name", detail[:attribute_label])
  end

  def test_active_filter_details_resolves_select_option_labels_for_value_label
    filter_params = { g: {
    "0" => { genre_eq: "action" }
    }
    }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    detail = @form.active_filter_details.first
    assert_equal("action", detail[:value])
    assert_equal("Action", detail[:value_label])
  end

  def test_search_fields_dsl_stores_search_fields_defined_in_the_class
    assert_equal(%i[name genre tenant_name], SearchableMovieFilterForm.defined_search_fields)
  end

  def test_search_fields_dsl_returns_search_fields_via_instance_method
    @form = SearchableMovieFilterForm.new(Movie.all, params({}))
    assert_equal(%i[name genre tenant_name], @form.search_fields)
  end

  def test_search_fields_dsl_returns_empty_array_for_forms_without_search_fields
    @form = MovieFilterForm.new(@tenant.movies, params({}))
    assert_equal([], @form.search_fields)
  end

  def test_search_enabled_returns_true_when_search_fields_defined
    @form = SearchableMovieFilterForm.new(Movie.all, params({}))
    assert(@form.search_enabled?)
  end

  def test_search_enabled_returns_false_when_no_search_fields
    @form = MovieFilterForm.new(@tenant.movies, params({}))
    refute(@form.search_enabled?)
  end

  def test_search_field_name_builds_ransack_field_name_from_search_fields
    @form = SearchableMovieFilterForm.new(Movie.all, params({}))
    assert_equal("name_or_genre_or_tenant_name_cont", @form.search_field_name)
  end

  def test_search_field_name_returns_nil_when_no_search_fields
    @form = MovieFilterForm.new(@tenant.movies, params({}))
    assert_nil(@form.search_field_name)
  end

  def test_search_value_extracts_search_value_from_params
    filter_params = { name_or_genre_or_tenant_name_cont: "Iron" }
    @form = SearchableMovieFilterForm.new(Movie.all, params(filter_params))
    assert_equal("Iron", @form.search_value)
  end

  def test_search_value_returns_nil_when_no_search_value_in_params
    @form = SearchableMovieFilterForm.new(Movie.all, params({}))
    assert_nil(@form.search_value)
  end

  def test_search_config_returns_complete_search_configuration
    filter_params = { name_or_genre_or_tenant_name_cont: "Iron" }
    @form = SearchableMovieFilterForm.new(Movie.all, params(filter_params))
    config = @form.search_config
    assert_equal(%i[name genre tenant_name], config[:fields])
    assert_equal("Iron", config[:value])
    assert_equal("Search by name, genre, tenant name...", config[:placeholder])
  end

  def test_search_config_default_placeholder_is_localized
    @form = SearchableMovieFilterForm.new(Movie.all, params({}))
    I18n.with_locale(:es) do
      assert_equal("Buscar por name, genre, tenant name...", @form.search_config[:placeholder])
    end
  end

  def test_search_config_returns_nil_when_search_not_enabled
    @form = MovieFilterForm.new(@tenant.movies, params({}))
    assert_nil(@form.search_config)
  end

  def test_search_fields_via_initialize_parameter_accepts_search_fields_as_initialize_parameter
    @form = Bali::FilterForm.new(Movie.all, params({}), search_fields: %i[name description])
    assert_equal(%i[name description], @form.search_fields)
    assert_equal("name_or_description_cont", @form.search_field_name)
  end

  def test_search_fields_via_initialize_parameter_extracts_search_value_with_dynamic_search_fields
    filter_params = { name_or_description_cont: "Test" }
    @form = Bali::FilterForm.new(Movie.all, params(filter_params), search_fields: %i[name description])
    assert_equal("Test", @form.search_value)
  end

  def test_search_fields_via_initialize_parameter_prefers_instance_search_fields_over_class_dsl
    filter_params = { name_or_email_cont: "test@example.com" }
    @form = SearchableMovieFilterForm.new(Movie.all, params(filter_params), search_fields: %i[name email])
    assert_equal(%i[name email], @form.search_fields)
    assert_equal("test@example.com", @form.search_value)
  end

  def test_ransack_params_includes_basic_query_params
    @form = MovieFilterForm.new(@tenant.movies, params({ name_i_cont: "Iron" }))
    assert_equal("Iron", @form.ransack_params["name_i_cont"])
  end

  def test_ransack_params_includes_search_value_when_search_is_enabled
    filter_params = { name_or_genre_or_tenant_name_cont: "Iron" }
    @form = SearchableMovieFilterForm.new(Movie.all, params(filter_params))
    assert_equal("Iron", @form.ransack_params["name_or_genre_or_tenant_name_cont"])
  end

  def test_ransack_params_includes_groupings_when_present
    filter_params = { g: {
    "0" => { name_cont: "Iron", m: "or" }
    }
    }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    assert(@form.ransack_params[:g].present?)
    assert_equal("Iron", @form.ransack_params[:g]["0"]["name_cont"])
  end

  def test_ransack_params_includes_combinator_when_present
    filter_params = { g: {
    "0" => { name_cont: "Iron" }, "1" => { genre_eq: "action" }
    }, m: "or"
    }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    assert_equal("or", @form.ransack_params[:m])
  end

  def test_ransack_params_returns_complete_params_for_ransack
    filter_params = { name_or_genre_or_tenant_name_cont: "Iron", g: {
    "0" => { name_cont: "Man", m: "and" }
    }, m: "and"
    }
    @form = SearchableMovieFilterForm.new(Movie.all, params(filter_params))
    ransack_params = @form.ransack_params
    assert_equal("Iron", ransack_params["name_or_genre_or_tenant_name_cont"])
    assert(ransack_params[:g].present?)
    assert_equal("and", ransack_params[:m])
  end

  def test_search_integration_with_ransack_filters_results_using_search_value
    @tenant = Tenant.create(name: "Test Studio")
    @tenant.movies.create(name: "Iron Man", genre: "Action")
    @tenant.movies.create(name: "Snatch", genre: "Comedy")
    filter_params = { name_or_genre_cont: "Iron" }
    @form = Bali::FilterForm.new(Movie.all, params(filter_params), search_fields: %i[name genre])
    results = @form.result
    assert_includes(results.pluck(:name), "Iron Man")
    refute_includes(results.pluck(:name), "Snatch")
  end
end

class BaliFilterFormPersistenceTest < ActiveSupport::TestCase
  # Use memory store for these tests since test env uses null_store by default

  def setup
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear
  end

  def teardown
    Rails.cache = @original_cache
  end

  def params(filter_attributes)
    ActionController::Parameters.new(q: filter_attributes)
  end

  def cache_key_for(form_class)
    "#{form_class.name.tableize};;movies"
  end

  def test_stores_complete_filter_state_including_groupings
    filter_params = { g: {
      "0" => { name_cont: "Iron", genre_eq: "action", m: "or" }
    }, m: "and" }
    AdvancedMovieFilterForm.new(Movie.all, params(filter_params), storage_id: "movies")
    stored = Rails.cache.read(cache_key_for(AdvancedMovieFilterForm))
    assert_kind_of(Hash, stored)
    assert(stored[:groupings].present?)
    assert_equal("Iron", stored[:groupings]["0"]["name_cont"])
    assert_equal("and", stored[:combinator])
  end

  def test_stores_search_value
    filter_params = { name_or_genre_or_tenant_name_cont: "Iron" }
    SearchableMovieFilterForm.new(Movie.all, params(filter_params), storage_id: "movies")
    stored = Rails.cache.read(cache_key_for(SearchableMovieFilterForm))
    assert_equal("Iron", stored[:search_value])
  end

  def test_restores_complete_filter_state_when_persist_enabled_is_true
    filter_params = { g: {
      "0" => { name_cont: "Iron", m: "or" }
    }, m: "and", name_or_genre_or_tenant_name_cont: "Iron" }
    SearchableMovieFilterForm.new(Movie.all, params(filter_params), storage_id: "movies")
    @form = SearchableMovieFilterForm.new(Movie.all, params({}), storage_id: "movies", persist_enabled: true)
    assert(@form.filter_groups.present?)
    assert_equal("name", @form.filter_groups[0][:conditions].first[:attribute])
    assert_equal("and", @form.combinator)
    assert_equal("Iron", @form.search_value)
  end

  def test_does_not_restore_filter_state_when_persist_enabled_is_false
    filter_params = { g: {
      "0" => { name_cont: "Iron", m: "or" }
    }, m: "and", name_or_genre_or_tenant_name_cont: "Iron" }
    SearchableMovieFilterForm.new(Movie.all, params(filter_params), storage_id: "movies")
    @form = SearchableMovieFilterForm.new(Movie.all, params({}), storage_id: "movies", persist_enabled: false)
    assert_equal([], @form.filter_groups)
    assert_nil(@form.search_value)
  end

  def test_clears_all_filter_state_when_clear_filters_is_true
    filter_params = { g: { "0" => { name_cont: "Iron" } }, name_or_genre_or_tenant_name_cont: "Iron" }
    SearchableMovieFilterForm.new(Movie.all, params(filter_params), storage_id: "movies")
    clear_params = ActionController::Parameters.new(q: {}, clear_filters: true)
    @form = SearchableMovieFilterForm.new(Movie.all, clear_params, storage_id: "movies")
    assert_equal([], @form.filter_groups)
    assert_nil(@form.search_value)
    assert_nil(Rails.cache.read(cache_key_for(SearchableMovieFilterForm)))
  end

  def test_does_not_persist_when_storage_id_is_not_provided
    filter_params = { g: { "0" => { name_cont: "Iron" } } }
    AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    assert_nil(Rails.cache.read(cache_key_for(AdvancedMovieFilterForm)))
  end
end

class BaliFilterFormTestSimpleFilters < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create(name: "Test")
  end

  def params(filter_attributes)
    ActionController::Parameters.new(q: filter_attributes)
  end

  def test_simple_filter_dsl_stores_simple_filters_defined_in_the_class
    assert_equal(2, SimpleFilterableMovieFilterForm.defined_simple_filters.size)
  end

  def test_simple_filter_dsl_stores_attribute_collection_blank_label_and_default
    status_filter = SimpleFilterableMovieFilterForm.defined_simple_filters.find { |f| f[:attribute] == :status }
    assert_equal([ %w[Done done], %w[Draft draft] ], status_filter[:collection])
    assert_equal("All", status_filter[:blank])
    assert_equal("Movie Status", status_filter[:label])
    assert_equal("done", status_filter[:default])
  end

  def test_simple_filter_dsl_uses_nil_for_optional_fields_when_not_specified
    genre_filter = SimpleFilterableMovieFilterForm.defined_simple_filters.find { |f| f[:attribute] == :genre }
    assert_nil(genre_filter[:label])
    assert_nil(genre_filter[:default])
  end

  def test_simple_filter_inheritance_inherits_simple_filters_from_parent_class
    assert_equal(3, ExtendedSimpleFilterForm.defined_simple_filters.size)
  end

  def test_simple_filter_inheritance_includes_parent_simple_filters
    attributes = ExtendedSimpleFilterForm.defined_simple_filters.pluck(:attribute)
    assert_equal(%i[genre status indie].sort, attributes.sort)
  end

  def test_simple_filter_inheritance_does_not_modify_parent_class_simple_filters
    assert_equal(2, SimpleFilterableMovieFilterForm.defined_simple_filters.size)
  end

  def test_simple_filters_returns_simple_filters_from_class_dsl
    @form = SimpleFilterableMovieFilterForm.new(Movie.all, params({}))
    assert_equal(2, @form.simple_filters.size)
  end

  def test_simple_filters_returns_empty_array_for_forms_without_simple_filter_definitions
    @form = MovieFilterForm.new(@tenant.movies, params({}))
    assert_equal([], @form.simple_filters)
  end

  def test_simple_filters_enabled_returns_true_when_simple_filters_defined
    @form = SimpleFilterableMovieFilterForm.new(Movie.all, params({}))
    assert(@form.simple_filters_enabled?)
  end

  def test_simple_filters_enabled_returns_false_when_no_simple_filters
    @form = MovieFilterForm.new(@tenant.movies, params({}))
    refute(@form.simple_filters_enabled?)
  end

  def test_simple_filters_config_returns_complete_configuration_for_each_filter
    @form = SimpleFilterableMovieFilterForm.new(Movie.all, params({}))
    config = @form.simple_filters_config
    assert_equal(2, config.size)
    genre_config = config.find { |c| c[:attribute] == :genre }
    assert_equal([ %w[Action action], %w[Comedy comedy], %w[Drama drama] ], genre_config[:collection])
    assert_equal("All Genres", genre_config[:blank])
    assert_equal("Genre", genre_config[:label]) # inferred from attribute
    assert_nil(genre_config[:value])
  end

  def test_simple_filters_config_includes_current_value_from_params
    filter_params = { genre_eq: "action" }
    @form = SimpleFilterableMovieFilterForm.new(Movie.all, params(filter_params))
    config = @form.simple_filters_config
    genre_config = config.find { |c| c[:attribute] == :genre }
    assert_equal("action", genre_config[:value])
  end

  def test_simple_filters_config_includes_default_value
    @form = SimpleFilterableMovieFilterForm.new(Movie.all, params({}))
    config = @form.simple_filters_config
    status_config = config.find { |c| c[:attribute] == :status }
    assert_equal("done", status_config[:default])
  end

  def test_simple_filters_config_uses_custom_label_when_provided
    @form = SimpleFilterableMovieFilterForm.new(Movie.all, params({}))
    config = @form.simple_filters_config
    status_config = config.find { |c| c[:attribute] == :status }
    assert_equal("Movie Status", status_config[:label])
  end

  def test_simple_filters_config_returns_nil_when_simple_filters_not_enabled
    @form = MovieFilterForm.new(@tenant.movies, params({}))
    assert_nil(@form.simple_filters_config)
  end

  def test_simple_filters_active_returns_false_when_no_filter_values_in_params
    @form = SimpleFilterableMovieFilterForm.new(Movie.all, params({}))
    refute(@form.simple_filters_active?)
  end

  def test_simple_filters_active_returns_true_when_filter_value_present_in_params
    filter_params = { genre_eq: "action" }
    @form = SimpleFilterableMovieFilterForm.new(Movie.all, params(filter_params))
    assert(@form.simple_filters_active?)
  end

  def test_simple_filters_active_returns_true_with_multiple_active_filters
    filter_params = { genre_eq: "action", status_eq: "done" }
    @form = SimpleFilterableMovieFilterForm.new(Movie.all, params(filter_params))
    assert(@form.simple_filters_active?)
  end

  def test_simple_filters_via_initialize_parameter_accepts_simple_filters_as_initialize_parameter
    simple_filters_config = [
    { attribute: :category, collection: [ %w[A a], %w[B b] ], blank: "All" }
    ]
    @form = Bali::FilterForm.new(Movie.all, params({}), simple_filters: simple_filters_config)
    assert_equal(1, @form.simple_filters.size)
    assert_equal(:category, @form.simple_filters.first[:attribute])
  end

  def test_simple_filters_via_initialize_parameter_prefers_instance_simple_filters_over_class_dsl
    custom_filters = [
    { attribute: :custom, collection: [ %w[X x] ], blank: "All Custom" }
    ]
    @form = SimpleFilterableMovieFilterForm.new(Movie.all, params({}), simple_filters: custom_filters)
    assert_equal(1, @form.simple_filters.size)
    assert_equal(:custom, @form.simple_filters.first[:attribute])
  end

  def test_simple_filters_via_initialize_parameter_extracts_current_values_from_params
    simple_filters_config = [
    { attribute: :category, collection: [ %w[A a], %w[B b] ], blank: "All" }
    ]
    filter_params = { category_eq: "a" }
    @form = Bali::FilterForm.new(Movie.all, params(filter_params), simple_filters: simple_filters_config)
    config = @form.simple_filters_config
    assert_equal("a", config.first[:value])
  end

  def test_simple_filter_with_callable_collection_resolves_proc_collections_at_config_time
    simple_filters_config = [
    { attribute: :dynamic, collection: -> { [ %w[Dynamic dynamic] ] }, blank: "All"
    }
    ]
    @form = Bali::FilterForm.new(Movie.all, params({}), simple_filters: simple_filters_config)
    config = @form.simple_filters_config
    assert_equal([ %w[Dynamic dynamic] ], config.first[:collection])
  end

  def test_simple_search_config_returns_search_config_hash_when_search_fields_configured
    @form = Bali::FilterForm.new(Movie.all, params({}), search_fields: %i[name genre])
    config = @form.simple_search_config
    assert_kind_of(Hash, config)
    assert_equal("q[name_or_genre_cont]", config[:field_name])
    assert_equal("Search by name, genre...", config[:placeholder])
  end

  def test_simple_search_config_includes_current_search_value_from_params
    filter_params = { name_or_genre_cont: "SAP" }
    @form = Bali::FilterForm.new(Movie.all, params(filter_params), search_fields: %i[name genre])
    config = @form.simple_search_config
    assert_equal("SAP", config[:value])
  end

  def test_simple_search_config_returns_nil_when_search_fields_not_configured
    @form = Bali::FilterForm.new(Movie.all, params({}))
    assert_nil(@form.simple_search_config)
  end

  def test_simple_search_config_uses_custom_placeholder_when_provided
    @form = Bali::FilterForm.new(
    Movie.all, params({}), search_fields: %i[name], search_placeholder: "Find movies..."
    )
    config = @form.simple_search_config
    assert_equal("Find movies...", config[:placeholder])
  end
end
