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

# Test form declaring simple-UI-only filters
class SimpleFilterableMovieFilterForm < Bali::FilterForm
  filter_attribute :genre, type: :select, simple: true, advanced: false,
                   options: [ %w[Action action], %w[Comedy comedy], %w[Drama drama] ],
                   blank: "All Genres"

  filter_attribute :status, type: :select, simple: true, advanced: false,
                   options: [ %w[Done done], %w[Draft draft] ],
                   blank: "All",
                   label: "Movie Status",
                   default: "done"
end

# Test simple filter inheritance
class ExtendedSimpleFilterForm < SimpleFilterableMovieFilterForm
  filter_attribute :indie, type: :select, simple: true, advanced: false,
                   options: [ [ true, true ], [ false, false ] ],
                   blank: "Any",
                   label: "Indie Film"
end

# Unified DSL: one filter_attribute declaration feeding BOTH filter UIs (#644)
class UnifiedMovieFilterForm < Bali::FilterForm
  filter_attribute :genre, type: :select, simple: true,
                   options: -> { scope.order(:genre).distinct.pluck(:genre).compact.map { |g| [ g, g ] } },
                   blank: "All Genres"
  filter_attribute :name, type: :text
  filter_attribute :status, type: :select, simple: true, advanced: false,
                   options: [ %w[Done done], %w[Draft draft] ],
                   label: -> { "Estado" }, default: "draft", input: :slim_select
end

# A :date simple filter with an explicit predicate (regression: the declared
# predicate used to be silently discarded and replaced with :eq)
class DatePredicateFilterForm < Bali::FilterForm
  filter_attribute :created_at, type: :date, simple: true, advanced: false,
                   predicate: :gteq, label: "Created after"
end

# Test form with group_by_attribute DSL. No custom scope order so the
# group-first ordering is the sole ORDER BY (sort-within-groups assertions).
class GroupableMovieFilterForm < Bali::FilterForm
  group_by_attribute :genre, label: "Género"
  group_by_attribute :status

  attribute :genre_eq
end

# Enum-label casting (#670): las opciones del select son las ETIQUETAS del enum, que es lo
# que sale de `Movie.statuses.keys` — el caso que Ransack rompía casteando con el tipo crudo
# de la columna.
class EnumMovieFilterForm < Bali::FilterForm
  filter_attribute :status, type: :select,
                   options: -> { Movie.statuses.keys.map { |key| [ key.humanize, key ] } }

  attribute :status_eq
  attribute :status_not_eq
  attribute :status_cont
  attribute :status_gteq
end

class EnumSimpleFilterMovieForm < Bali::FilterForm
  filter_attribute :status, type: :select, simple: true, advanced: false,
                   options: [ %w[Done done], %w[Draft draft] ], blank: "All"
end

# Enum de STRING: nunca estuvo roto (Ransack no destruye la etiqueta y el EnumType la
# resuelve después). Está acá para clavar que la traducción es IDEMPOTENTE, no un cambio de
# comportamiento.
class StringEnumMovie < ActiveRecord::Base
  self.table_name = "movies"

  enum :genre, { action: "Action", comedy: "Comedy" }

  def self.ransackable_attributes(_auth_object = nil) = column_names
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

  # #817 — three surfaces narrow a listing and only one was represented here. A plain
  # FilterForm declares no attributes, so `attribute_names` is `["s"]` and this answered
  # `{}` no matter what the user had chosen; `Table` then read `active_filters?` as false
  # and offered "No records yet — create one" over a result the filters had emptied.
  def test_active_filters_counts_a_simple_filter_a_plain_form_never_declares
    simple_filters_config = [ { attribute: :category, collection: [ %w[A a] ], blank: "All" } ]
    @form = Bali::FilterForm.new(Movie.all, params({ category_eq: "a" }),
                                 simple_filters: simple_filters_config)

    assert(@form.active_filters?)
    assert_equal(1, @form.active_filters_count)
    assert_equal({ "category_eq" => "a" }, @form.active_filters)
  end

  def test_active_filters_counts_the_quick_search
    @form = Bali::FilterForm.new(Movie.all, params({ name_or_genre_cont: "Iron" }),
                                 search_fields: %i[name genre])

    assert(@form.active_filters?)
    assert_equal(1, @form.active_filters_count)
  end

  def test_active_filters_stays_false_on_a_plain_form_with_nothing_chosen
    simple_filters_config = [ { attribute: :category, collection: [ %w[A a] ], blank: "All" } ]
    @form = Bali::FilterForm.new(Movie.all, params({}), simple_filters: simple_filters_config,
                                                        search_fields: %i[name])

    refute(@form.active_filters?)
    assert_equal(0, @form.active_filters_count)
  end

  # `s` is Ransack's sort param. Sorting is not narrowing.
  def test_active_filters_ignores_the_sort_param
    @form = MovieFilterForm.new(@tenant.movies, params({ s: "name asc" }))
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
    expected = AdvancedMovieFilterForm.filter_attributes.map do |attr|
      attr.slice(:key, :type, :label, :options)
    end
    assert_equal(expected, @form.available_attributes)
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

  # --- R5 (ronda adversarial): la persistencia también cubre la agrupación ---

  def test_persists_and_restores_the_active_group_by
    # Sin group_by en el cache, volver al listado restauraba los filtros pero perdía la
    # agrupación — y una vista guardada que agrupa dejaba de reconocerse activa.
    grouped = ActionController::Parameters.new(q: { genre_eq: "action" }, group_by: "genre")
    GroupableMovieFilterForm.new(Movie.all, grouped, storage_id: "movies")

    stored = Rails.cache.read(cache_key_for(GroupableMovieFilterForm))
    assert_equal("genre", stored[:group_by].to_s)

    restored = GroupableMovieFilterForm.new(Movie.all, ActionController::Parameters.new,
                                            storage_id: "movies", persist_enabled: true)
    assert_equal("genre", restored.group_by.to_s)
  end

  def test_persists_the_group_by_even_while_it_is_suspended
    # La suspensión fuera del modo tabla es un predicado DERIVADO, nunca `@group_by = nil`:
    # anulando el ivar, entrar al listado en tarjetas envenenaba la caché con nil y volver a
    # la tabla ya no encontraba la agrupación.
    suspended = ActionController::Parameters.new(
      q: { genre_eq: "action" }, group_by: "genre", view: "grid"
    )
    form = GroupableMovieFilterForm.new(Movie.all, suspended, storage_id: "movies")
    assert(form.group_by_suspended?)

    stored = Rails.cache.read(cache_key_for(GroupableMovieFilterForm))
    assert_equal("genre", stored[:group_by].to_s)
  end

  def test_a_group_by_from_the_url_beats_the_persisted_one
    # Elegir una agrupación llega SOLO como `?group_by=`: los filtros viven en la caché, así
    # que la URL no los trae y corre el branch de restaurar, que pisaba el click recién hecho
    # con la agrupación vieja. El control no hacía nada y el viaje tarjetas↔tabla la perdía.
    GroupableMovieFilterForm.new(Movie.all, params(genre_eq: "action"), storage_id: "movies")
    assert_nil(Rails.cache.read(cache_key_for(GroupableMovieFilterForm))[:group_by])

    clicked = GroupableMovieFilterForm.new(
      Movie.all, ActionController::Parameters.new(group_by: "genre"),
      storage_id: "movies", persist_enabled: true
    )
    assert_equal(:genre, clicked.group_by)
  end

  # El estado que se RENDERIZA y el que se GUARDA tienen que ser el mismo, o la caché termina
  # contando otra historia: el click llega SIN `q` (los filtros ya viven en la caché), corre el
  # branch de restaurar, y renderizar la elección nueva sin escribirla dejaba el mismo render
  # bien y el siguiente request sin el param resucitando la agrupación vieja.
  def test_a_group_by_chosen_while_restoring_is_persisted
    GroupableMovieFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { genre_eq: "action" }, group_by: "genre"),
      storage_id: "movies"
    )

    clicked = GroupableMovieFilterForm.new(
      Movie.all, ActionController::Parameters.new(group_by: "status"),
      storage_id: "movies", persist_enabled: true
    )
    assert_equal(:status, clicked.group_by)

    returning = GroupableMovieFilterForm.new(Movie.all, ActionController::Parameters.new,
                                             storage_id: "movies", persist_enabled: true)
    assert_equal(:status, returning.group_by)
    assert_equal("action", returning.genre_eq, "guardar la agrupación no puede perder los filtros")
  end

  def test_turning_the_grouping_off_survives_the_next_request
    GroupableMovieFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { genre_eq: "action" }, group_by: "genre"),
      storage_id: "movies"
    )
    GroupableMovieFilterForm.new(Movie.all, ActionController::Parameters.new(group_by: ""),
                                 storage_id: "movies", persist_enabled: true)

    returning = GroupableMovieFilterForm.new(Movie.all, ActionController::Parameters.new,
                                             storage_id: "movies", persist_enabled: true)
    assert_nil(returning.group_by)
  end

  # Sin filtros previos no hay nada en la caché, y elegir una agrupación tampoco escribía nada:
  # la elección duraba un solo render.
  def test_a_group_by_chosen_without_any_stored_state_is_persisted
    GroupableMovieFilterForm.new(Movie.all, ActionController::Parameters.new(group_by: "genre"),
                                 storage_id: "movies", persist_enabled: true)

    returning = GroupableMovieFilterForm.new(Movie.all, ActionController::Parameters.new,
                                             storage_id: "movies", persist_enabled: true)
    assert_equal(:genre, returning.group_by)
  end

  def test_turning_the_grouping_off_is_not_undone_by_the_persisted_one
    # `?group_by=` vacío es "sin agrupación", y tiene que ser distinguible de "no vino nada":
    # con la persistencia encendida, un param ausente significa restaurar la caché — o sea que
    # apagar la agrupación la resucitaba en el mismo render.
    GroupableMovieFilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { genre_eq: "action" }, group_by: "genre"),
      storage_id: "movies"
    )

    cleared = GroupableMovieFilterForm.new(
      Movie.all, ActionController::Parameters.new(group_by: ""),
      storage_id: "movies", persist_enabled: true
    )
    assert_nil(cleared.group_by)
  end

  def test_clearing_the_search_does_not_restore_state_when_persistence_is_off
    # Con la persistencia apagada el usuario pidió que el server NO le devuelva estado:
    # limpiar la búsqueda no puede ser la puerta trasera por la que reaparecen filtros.
    MovieFilterForm.new(Movie.all, params(name_i_cont: "iron"), storage_id: "movies")

    cleared = MovieFilterForm.new(
      Movie.all, ActionController::Parameters.new(clear_search: true),
      storage_id: "movies", persist_enabled: false
    )
    assert_nil(cleared.name_i_cont)

    still_there = MovieFilterForm.new(
      Movie.all, ActionController::Parameters.new(clear_search: true),
      storage_id: "movies", persist_enabled: true
    )
    assert_equal("iron", still_there.name_i_cont)
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

  # Regresión: una vista guardada "vacía" (ver todo) aplicada con persist_enabled: true no
  # debe perder ante la caché de la visita anterior — una vista es un estado completo, y
  # eso incluye el estado vacío. Antes del fix, has_filter_params no distinguía "no vino
  # vista" de "vino una vista vacía" y ambos caían al branch de restaurar la caché.
  def test_an_applied_view_with_a_blank_payload_beats_stale_cached_filters
    filter_params = { name_or_genre_or_tenant_name_cont: "Iron" }
    SearchableMovieFilterForm.new(Movie.all, params(filter_params), storage_id: "movies")

    blank_view = Struct.new(:id, :name, :payload, keyword_init: true).new(id: 1, name: "Ver todo", payload: {})
    store = Struct.new(:views) do
      def list = views
      def find(id) = views.find { |view| view.id.to_s == id.to_s }
    end.new([ blank_view ])

    @form = SearchableMovieFilterForm.new(
      Movie.all, ActionController::Parameters.new(saved_view: "1"),
      storage_id: "movies", persist_enabled: true, saved_views_store: store
    )

    assert_nil(@form.search_value, "la vista vacía debe ganarle a la búsqueda vieja en caché")
    assert_equal([], @form.filter_groups)
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

  # `search_config` is the single builder both filter surfaces consume; there used to
  # be a second one (`simple_search_config`) emitting a different shape for SimpleFilters.
  def test_search_config_declares_the_columns_not_the_ransack_param
    @form = Bali::FilterForm.new(Movie.all, params({}), search_fields: %i[name genre])
    config = @form.search_config
    assert_kind_of(Hash, config)
    assert_equal(%i[name genre], config[:fields])
    assert_equal("Search by name, genre...", config[:placeholder])
    assert_equal("q[name_or_genre_cont]", Bali::SearchConfig.wrap(config).param_name)
  end

  def test_search_config_carries_the_search_icon
    @form = Bali::FilterForm.new(Movie.all, params({}), search_fields: %i[name], search_icon: "search")
    assert_equal("search", @form.search_config[:icon])
  end

  def test_search_config_includes_current_search_value_from_params
    filter_params = { name_or_genre_cont: "SAP" }
    @form = Bali::FilterForm.new(Movie.all, params(filter_params), search_fields: %i[name genre])
    assert_equal("SAP", @form.search_config[:value])
  end

  def test_search_config_uses_custom_placeholder_when_provided
    @form = Bali::FilterForm.new(
    Movie.all, params({}), search_fields: %i[name], search_placeholder: "Find movies..."
    )
    assert_equal("Find movies...", @form.search_config[:placeholder])
  end
end

class BaliFilterFormGroupByTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create(name: "Test Studio")
    # Action: 3, Comedy: 2, Drama: 1 (6 total across multiple "pages")
    @tenant.movies.create(name: "Aardvark", genre: "Action", status: :draft)
    @tenant.movies.create(name: "Blade", genre: "Action", status: :draft)
    @tenant.movies.create(name: "Crash", genre: "Action", status: :done)
    @tenant.movies.create(name: "Ditto", genre: "Comedy", status: :draft)
    @tenant.movies.create(name: "Echo", genre: "Comedy", status: :done)
    @tenant.movies.create(name: "Fargo", genre: "Drama", status: :draft)
  end

  # `view:` es el modo de visualización tal cual llega de la URL; `extra` deja escribir el
  # param con otro nombre para los tests de `view_param:`.
  def group_params(group_by, q: {}, view: nil, **extra)
    ActionController::Parameters.new(
      { q: ActionController::Parameters.new(q), group_by: group_by, view: view }.merge(extra)
    )
  end

  # --- Whitelist / security boundary ---

  def test_group_by_ignores_undeclared_attribute
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("name"))
    assert_nil(form.group_by)
    refute(form.group_by_active?)
  end

  def test_group_by_rejects_sql_injection_shaped_value
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre) UNION SELECT--"))
    assert_nil(form.group_by)
    assert_equal({}, form.group_counts)
    # The raw value must never reach ordering
    refute_includes(form.ransack_params["s"].to_s, "UNION")
  end

  def test_group_by_is_blank_when_param_absent
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params(nil))
    assert_nil(form.group_by)
  end

  # --- Activation + ordering (sort-within-groups) ---

  def test_group_by_activates_for_declared_attribute
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre"))
    assert_equal(:genre, form.group_by)
    assert(form.group_by_active?)
  end

  def test_group_by_orders_by_group_field_first
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre"))
    assert_equal([ "genre asc" ], form.ransack_params["s"])
    assert_match(/ORDER BY.*genre/i, form.result.to_sql)
  end

  def test_group_by_keeps_user_sort_secondary
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", q: { s: "name desc" }))
    assert_equal([ "genre asc", "name desc" ], form.ransack_params["s"])

    order_clause = form.result.to_sql[/ORDER BY(.*)\z/i, 1]
    assert(order_clause.index("genre") < order_clause.index("name"),
           "group field must be ordered before the user sort")
  end

  # --- Global counts (independent of pagination) ---

  def test_group_counts_returns_global_totals
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre"))
    assert_equal({ "Action" => 3, "Comedy" => 2, "Drama" => 1 }, form.group_counts)
  end

  def test_group_counts_independent_of_pagination
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre"))
    # Simulate a page slice; group_counts still counts the full filtered set.
    assert_equal(2, form.result.limit(2).to_a.size)
    assert_equal(6, form.group_counts.values.sum)
  end

  def test_group_counts_respects_active_filters
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", q: { genre_eq: "Action" }))
    assert_equal({ "Action" => 3 }, form.group_counts)
  end

  def test_group_counts_works_with_active_user_sort
    # unscope(:order) prevents the ORDER BY (incl. the group sort) from
    # conflicting with GROUP BY under strict SQL.
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", q: { s: "name desc" }))
    assert_equal(3, form.group_counts["Action"])
  end

  def test_group_counts_by_status_returns_enum_label_keys
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("status"))
    assert_equal({ "draft" => 4, "done" => 2 }, form.group_counts)
  end

  # --- Inactive parity ---

  def test_group_counts_empty_when_inactive
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params(nil))
    assert_equal({}, form.group_counts)
  end

  def test_ransack_params_sort_unchanged_when_group_by_inactive
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params(nil, q: { s: "name asc" }))
    assert_equal("name asc", form.ransack_params["s"])
  end

  # --- Suspensión fuera del modo tabla: el ESTADO sobrevive, la APLICACIÓN se apaga ---
  #
  # Una tabla es la única superficie donde una banda de grupo significa algo. En tarjetas el
  # mismo ordenamiento reacomodaba el contenido sin que nada en pantalla lo explicara, así
  # que ahí la agrupación se SUSPENDE — pero el param tiene que sobrevivir, o volver a la
  # tabla ya no la encuentra.

  def test_group_by_ordering_is_suspended_outside_table_mode
    form = GroupableMovieFilterForm.new(
      @tenant.movies, group_params("genre", q: { s: "name desc" }, view: "grid")
    )

    assert_equal("name desc", form.ransack_params["s"])
    refute_match(/genre/i, form.result.to_sql[/ORDER BY(.*)\z/i, 1].to_s)
  end

  def test_group_counts_are_empty_when_grouping_is_suspended
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "grid"))
    assert_equal({}, form.group_counts)
  end

  def test_group_by_state_survives_suspension
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "grid"))

    # ESTADO: intacto — es lo que preserva el hidden field del form de filtros.
    assert_equal(:genre, form.group_by)
    assert(form.group_by_active?)
    # MODO y APLICACIÓN: apagados.
    refute(form.group_by_applies?)
    assert_nil(form.group_by_applied)
    refute(form.group_by_applied?)
    assert(form.group_by_suspended?)
  end

  def test_group_by_applies_in_table_mode
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "table"))

    assert(form.group_by_applies?)
    assert_equal(:genre, form.group_by_applied)
    refute(form.group_by_suspended?)
    assert_equal([ "genre asc" ], form.ransack_params["s"])
    assert_equal({ "Action" => 3, "Comedy" => 2, "Drama" => 1 }, form.group_counts)
  end

  def test_group_by_applies_when_the_listing_has_no_view_switch
    # El caso de la enorme mayoría de los listados: sin `?view=` en la URL no hay modo que
    # pueda suspender nada.
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre"))

    assert(form.group_by_applies?)
    assert_equal(:genre, form.group_by_applied)
  end

  def test_group_by_modes_lets_the_host_declare_which_modes_apply_it
    kanban = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "kanban"),
                                          group_by_modes: %i[table kanban])
    assert(kanban.group_by_applied?)

    grid = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "grid"),
                                        group_by_modes: %i[table kanban])
    assert(grid.group_by_suspended?)
  end

  def test_group_by_modes_can_be_emptied_to_mean_no_mode_applies_it
    # `[]` NO es "no me dijeron nada": es el host declarando que ningún modo la aplica (quiere
    # el param preservado y guardado en una vista, nunca aplicado). Colapsándolo al default le
    # daba justo lo contrario, en silencio.
    never = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "table"),
                                         group_by_modes: [])

    assert(never.group_by_active?)
    refute(never.group_by_applies?)
    assert_nil(never.group_by_applied)
    assert_nil(never.ransack_params["s"])

    # Y tampoco por la puerta de atrás: sin `?view=` el escape de "sin modo aplica" la habría
    # vuelto a encender.
    bare = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre"), group_by_modes: [])
    refute(bare.group_by_applies?)
  end

  def test_display_mode_from_the_host_beats_the_url
    # Un listado cuya vista por default no es la tabla aterriza SIN `?view=`, y el form —que
    # solo mira la URL— daba por hecho que aplicaba: las tarjetas volvían ordenadas por grupo
    # sin ninguna banda que lo explicara.
    cards = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre"), display_mode: :grid)

    assert_equal(:grid, cards.display_mode)
    assert(cards.group_by_suspended?)
    assert_nil(cards.ransack_params["s"])

    # Con el modo en la URL el host igual manda: es el único que sabe qué está renderizando.
    forced = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "table"),
                                          display_mode: :grid)
    assert(forced.group_by_suspended?)
  end

  def test_view_param_selects_which_param_carries_the_display_mode
    custom = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", modo: "grid"),
                                          view_param: :modo)
    assert(custom.group_by_suspended?)

    # `view` dejó de ser el param que este form mira, así que no suspende nada.
    ignored = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "grid"),
                                           view_param: :modo)
    assert(ignored.group_by_applied?)
  end

  def test_a_view_saved_from_cards_still_carries_the_suspended_grouping
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "grid"))
    # String y no Symbol: este payload se compara contra uno que ya volvió de un jsonb, donde
    # todo es String, y `comparable_view_state` normaliza llaves pero no valores.
    assert_equal("genre", form.current_view_payload["group_by"])
  end

  # --- Options / configuration ---

  def test_group_by_options_returns_attributes_with_labels
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params(nil))
    options = form.group_by_options
    assert_equal("Género", options.find { |o| o[:attribute] == :genre }[:label])
    assert_equal("Status", options.find { |o| o[:attribute] == :status }[:label])
  end

  def test_group_by_enabled_reflects_declaration
    assert(GroupableMovieFilterForm.new(@tenant.movies, group_params(nil)).group_by_enabled?)
    refute(Bali::FilterForm.new(@tenant.movies, group_params(nil)).group_by_enabled?)
  end

  def test_group_by_via_initialize_parameter
    form = Bali::FilterForm.new(@tenant.movies, group_params("genre"), group_by_attributes: %i[genre status])
    assert_equal(:genre, form.group_by)
    assert_equal(%i[genre status], form.group_by_attributes)
  end
end

class BaliFilterFormTestUnifiedDsl < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create(name: "Test")
    @tenant.movies.create(name: "Snatch", genre: "crime", status: 0)
    @tenant.movies.create(name: "Heat", genre: "thriller", status: 0)
  end

  def params(filter_attributes)
    ActionController::Parameters.new(q: filter_attributes)
  end

  def test_unified_attribute_appears_in_both_uis
    form = UnifiedMovieFilterForm.new(@tenant.movies, params({}))
    assert_includes(form.available_attributes.pluck(:key), :genre)
    assert_includes(form.simple_filters_config.pluck(:attribute), :genre)
  end

  def test_options_proc_resolves_with_instance_context_for_the_advanced_ui
    form = UnifiedMovieFilterForm.new(@tenant.movies, params({}))
    genre = form.available_attributes.find { |a| a[:key] == :genre }
    assert_equal([ %w[crime crime], %w[thriller thriller] ], genre[:options])
  end

  def test_options_proc_sees_only_the_scoped_relation
    other_tenant = Tenant.create(name: "Other")
    other_tenant.movies.create(name: "Z", genre: "zombie", status: 0)
    form = UnifiedMovieFilterForm.new(@tenant.movies, params({}))
    genre = form.available_attributes.find { |a| a[:key] == :genre }
    refute_includes(genre[:options].map(&:last), "zombie")
  end

  def test_options_proc_resolves_for_the_simple_ui_too
    form = UnifiedMovieFilterForm.new(@tenant.movies, params({}))
    genre = form.simple_filters_config.find { |c| c[:attribute] == :genre }
    assert_equal([ %w[crime crime], %w[thriller thriller] ], genre[:collection])
    assert_equal("All Genres", genre[:blank])
  end

  def test_advanced_false_keeps_the_attribute_out_of_the_popover
    form = UnifiedMovieFilterForm.new(@tenant.movies, params({}))
    refute_includes(form.available_attributes.pluck(:key), :status)
  end

  def test_input_overrides_the_simple_widget
    form = UnifiedMovieFilterForm.new(@tenant.movies, params({}))
    status = form.simple_filters_config.find { |c| c[:attribute] == :status }
    assert_equal(:slim_select, status[:type])
    assert_equal("draft", status[:default])
  end

  def test_label_proc_resolves_at_instance_time
    form = UnifiedMovieFilterForm.new(@tenant.movies, params({}))
    status = form.simple_filters_config.find { |c| c[:attribute] == :status }
    assert_equal("Estado", status[:label])
  end

  def test_simple_only_filter_stays_out_of_the_advanced_popover
    form = SimpleFilterableMovieFilterForm.new(@tenant.movies, params({}))
    assert_equal([], form.available_attributes)
  end

  def test_simple_text_attribute_without_input_raises
    error = assert_raises(ArgumentError) do
      Class.new(Bali::FilterForm) { filter_attribute :notes, type: :text, simple: true }
    end
    assert_match(/no simple filter widget/, error.message)
  end

  def test_unknown_simple_input_raises
    error = assert_raises(ArgumentError) do
      Class.new(Bali::FilterForm) { filter_attribute :notes, type: :select, simple: true, input: :bogus }
    end
    assert_match(/unknown input/, error.message)
  end

  def test_date_simple_filter_honors_declared_predicate
    form = DatePredicateFilterForm.new(Movie.all, params({ created_at_gteq: "2024-01-01" }))
    assert_includes(form.simple_filters_permitted_keys, "created_at_gteq")
    assert_equal("2024-01-01", form.ransack_params["created_at_gteq"])
  end

  def test_unified_simple_value_reaches_ransack_params_and_result
    form = UnifiedMovieFilterForm.new(@tenant.movies, params({ genre_eq: "crime" }))
    assert_equal("crime", form.ransack_params["genre_eq"])
    assert_equal([ "Snatch" ], form.result.pluck(:name))
  end

  # --- Saved views (B2): combinaciones de filtros con nombre vía saved_views_store ---

  # Store fake que cumple el contrato de SavedViewsConfiguration (list/find/save/delete).
  class FakeSavedViewsStore
    SavedView = Struct.new(:id, :name, :payload, keyword_init: true)

    def initialize(views = [])
      @views = views
    end

    def list = @views
    def find(id) = @views.find { |view| view.id.to_s == id.to_s }

    def save(name:, payload:)
      SavedView.new(id: @views.size + 1, name: name, payload: payload).tap { |view| @views << view }
    end

    def delete(id) = @views.reject! { |view| view.id.to_s == id.to_s }
  end

  def store_with_view(payload, id: 1, name: "Mi vista")
    FakeSavedViewsStore.new([ FakeSavedViewsStore::SavedView.new(id: id, name: name, payload: payload) ])
  end

  def test_saved_views_disabled_without_store
    form = MovieFilterForm.new(Movie.all, params({}))
    assert_not form.saved_views_enabled?
    assert_empty form.saved_views
    assert_nil form.current_saved_view
  end

  def test_applying_a_saved_view_replaces_filter_state_from_its_payload
    store = store_with_view({ "attributes" => { "name_i_cont" => "Matrix" }, "combinator" => "or",
                              "search_value" => nil })
    form = MovieFilterForm.new(
      Movie.all,
      ActionController::Parameters.new(q: { name_i_cont: "otra cosa" }, saved_view: "1"),
      saved_views_store: store
    )

    assert_equal "Mi vista", form.current_saved_view.name
    # La vista REEMPLAZA el estado — lo que venía en q no sobrevive.
    assert_equal "Matrix", form.name_i_cont
    assert_equal "or", form.combinator
  end

  def test_saved_view_payload_attributes_are_gated_by_declared_attribute_names
    store = store_with_view({ "attributes" => { "name_i_cont" => "Matrix", "no_declarado_eq" => "x" } })
    form = MovieFilterForm.new(Movie.all, ActionController::Parameters.new(saved_view: "1"),
                               saved_views_store: store)

    assert_equal "Matrix", form.name_i_cont
    assert_not form.attributes.key?("no_declarado_eq")
  end

  def test_saved_view_group_by_repasses_the_whitelist
    applied = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new(saved_view: "1"),
                                   group_by_attributes: [ :genre ],
                                   saved_views_store: store_with_view({ "group_by" => "genre" }))
    assert_equal :genre, applied.group_by

    hostile = Bali::FilterForm.new(Movie.all, ActionController::Parameters.new(saved_view: "1"),
                                   group_by_attributes: [ :genre ],
                                   saved_views_store: store_with_view({ "group_by" => "no_declarado" }))
    assert_nil hostile.group_by
  end

  def test_unknown_saved_view_id_falls_back_to_normal_params_flow
    store = FakeSavedViewsStore.new
    form = MovieFilterForm.new(
      Movie.all,
      ActionController::Parameters.new(q: { name_i_cont: "Snatch" }, saved_view: "999"),
      saved_views_store: store
    )

    assert_nil form.current_saved_view
    assert_equal "Snatch", form.name_i_cont
  end

  def test_current_view_payload_captures_the_present_state_without_blanks
    form = MovieFilterForm.new(Movie.all, params({ name_i_cont: "Matrix" }))
    payload = form.current_view_payload

    assert_equal({ "name_i_cont" => "Matrix" }, payload["attributes"])
    assert_not payload.key?("groupings"), "sin agrupaciones no viaja la llave (compact)"
  end

  def test_saved_view_columns_come_from_the_applied_view_payload
    store = store_with_view({ "attributes" => {}, "columns" => [ 0, 2 ] })
    form = MovieFilterForm.new(Movie.all, ActionController::Parameters.new(saved_view: "1"),
                               saved_views_store: store)

    assert_equal [ 0, 2 ], form.saved_view_columns
  end

  # #823 — a simple filter's value is never an ActiveModel attribute (it lives in q_params
  # and goes straight to Ransack), so `attributes` could not see it and a view saved from a
  # simplified index was born without its own cut.
  def test_current_view_payload_carries_the_simple_filters
    form = Bali::FilterForm.new(
      Movie.all, params({ category_eq: "a" }),
      simple_filters: [ { attribute: :category, collection: [ %w[A a] ], blank: "All" } ]
    )

    assert_equal({ "category_eq" => "a" }, form.current_view_payload["simple_filters"])
  end

  def test_current_view_payload_omits_the_key_with_no_simple_filter_chosen
    form = Bali::FilterForm.new(
      Movie.all, params({}),
      simple_filters: [ { attribute: :category, collection: [ %w[A a] ], blank: "All" } ]
    )

    assert_not form.current_view_payload.key?("simple_filters")
  end

  def test_applying_a_view_restores_its_simple_filters
    store = store_with_view({ "simple_filters" => { "category_eq" => "a" } })
    form = Bali::FilterForm.new(
      Movie.all, ActionController::Parameters.new(saved_view: "1"),
      simple_filters: [ { attribute: :category, collection: [ %w[A a] ], blank: "All" } ],
      saved_views_store: store
    )

    assert_equal("a", form.simple_filters_config.first[:value])
    assert(form.active_filters?)
  end

  # Una vista es un estado COMPLETO, no un merge: el mismo contrato que ya rige para
  # `attributes`. Un payload viejo, guardado antes de que la llave existiera, limpia.
  def test_applying_a_view_without_simple_filters_clears_the_ones_in_the_url
    store = store_with_view({ "attributes" => {} })
    form = Bali::FilterForm.new(
      Movie.all, ActionController::Parameters.new(q: { category_eq: "a" }, saved_view: "1"),
      simple_filters: [ { attribute: :category, collection: [ %w[A a] ], blank: "All" } ],
      saved_views_store: store
    )

    assert_nil(form.simple_filters_config.first[:value])
  end
end

# Enum-label casting (#670). Síntoma: filtrar Status = "Done" devolvía exactamente los
# registros contrarios. Causa: Ransack castea con el tipo CRUDO de la columna, así que sobre
# un enum entero "done".to_i es 0 — el valor de `draft`.
class EnumCastingFilterFormTest < ActiveSupport::TestCase
  def setup
    @tenant = Tenant.create(name: "Test")
    @done = @tenant.movies.create(name: "Iron man 3", status: :done)
    @draft = @tenant.movies.create(name: "Iron man 2", status: :draft)
    Rails.cache.clear
  end

  def params(filter_attributes)
    ActionController::Parameters.new(q: filter_attributes)
  end

  # LA reproducción: el shape exacto que emite el builder de Bali::Filters. Se afirma sobre
  # el CONJUNTO y no sobre el conteo — con dos registros, un conteo de 1 pasa igual de bien
  # filtrando por el estado equivocado.
  def test_an_enum_label_in_a_grouping_filters_by_the_right_records
    form = EnumMovieFilterForm.new(@tenant.movies, params({ g: { "0" => { status_in: [ "done" ], m: "and" } } }))

    assert_equal [ "done" ], form.result.pluck(:status).uniq
    assert_equal [ @done.name ], form.result.pluck(:name)
  end

  def test_an_enum_label_in_a_declared_attribute_filters_by_the_right_records
    form = EnumMovieFilterForm.new(@tenant.movies, params({ status_eq: "done" }))

    assert_equal 1, form.ransack_params["status_eq"]
    assert_equal [ "done" ], form.result.pluck(:status).uniq
  end

  def test_an_enum_label_in_a_simple_filter_filters_by_the_right_records
    form = EnumSimpleFilterMovieForm.new(@tenant.movies, params({ status_eq: "done" }))

    assert_equal 1, form.ransack_params["status_eq"]
    assert_equal [ "done" ], form.result.pluck(:status).uniq
  end

  # Los predicados NEGADOS son donde una traducción rota es invisible: la negación devuelve el
  # COMPLEMENTO, un conjunto plausible y no vacío. Por eso se afirma el set, no el param.
  def test_a_negated_enum_label_filters_by_the_right_records
    excluded = EnumMovieFilterForm.new(@tenant.movies, params({ g: { "0" => { status_not_in: [ "done" ] } } }))
    different = EnumMovieFilterForm.new(@tenant.movies, params({ status_not_eq: "done" }))

    assert_equal [ "draft" ], excluded.result.pluck(:status).uniq
    assert_equal [ "draft" ], different.result.pluck(:status).uniq
  end

  # Un valor CRUDO conocido pasa intacto: una app que ya mandaba 0/1 sigue andando igual.
  def test_a_raw_enum_value_is_left_alone
    raw = EnumMovieFilterForm.new(@tenant.movies, params({ status_eq: "1" }))

    assert_equal "1", raw.ransack_params["status_eq"]
    assert_equal [ "done" ], raw.result.pluck(:status).uniq
  end

  # Un valor que no es NI etiqueta NI valor crudo no puede pasar intacto: Ransack lo castea
  # con el tipo crudo de la columna y `"Done".to_i` es 0, o sea el PRIMER miembro del enum —
  # el bug original, de vuelta, invertido y en silencio. El centinela hace que la igualdad no
  # devuelva nada y la negación devuelva todo, que es la respuesta honesta.
  def test_a_value_that_is_neither_a_label_nor_a_raw_value_matches_nothing
    humanized = EnumMovieFilterForm.new(@tenant.movies, params({ status_eq: "Done" }))
    renamed = EnumMovieFilterForm.new(@tenant.movies, params({ g: { "0" => { status_in: [ "completed" ] } } }))
    negated = EnumMovieFilterForm.new(@tenant.movies, params({ status_not_eq: "completed" }))

    assert_empty humanized.result
    assert_empty renamed.result
    assert_equal %w[done draft].sort, negated.result.pluck(:status).sort
  end

  # Ransack ignora las condiciones en blanco: mapear el vacío convertiría un select sin elegir
  # en "no muestres nada" — cambiar un bug de datos equivocados por otro.
  def test_a_blank_value_does_not_filter
    form = EnumMovieFilterForm.new(@tenant.movies, params({ status_eq: "" }))

    assert_equal %w[done draft].sort, form.result.pluck(:status).sort
  end

  # `FilterForm.new(Movie, params)` —la forma que enseña la propia API de Ransack— no responde
  # a `model`: preguntando por ahí la traducción entera era un no-op silencioso y el filtro
  # devolvía los registros contrarios, sin una sola señal.
  def test_the_model_class_as_scope_casts_like_a_relation
    from_class = EnumMovieFilterForm.new(Movie, params({ g: { "0" => { status_in: [ "done" ] } } }))
    from_relation = EnumMovieFilterForm.new(Movie.all, params({ g: { "0" => { status_in: [ "done" ] } } }))

    assert_equal [ "done" ], from_class.result.pluck(:status).uniq
    assert_equal from_relation.result.pluck(:id), from_class.result.pluck(:id)
  end

  def test_enum_labels_are_cast_inside_nested_groupings
    filter_params = { g: { "0" => { g: { "0" => { status_eq: "done" } }, m: "or" } } }
    form = EnumMovieFilterForm.new(@tenant.movies, params(filter_params))

    assert_equal 1, form.ransack_params[:g]["0"]["g"]["0"]["status_eq"]
    # Ransack DESCARTA una condición que no entiende sin levantar nada, así que el param solo
    # no distingue "filtró bien" de "tiró la condición y devolvió todo".
    assert_equal [ @done.name ], form.result.pluck(:name)
  end

  # `q[g][]` (groupings como ARRAY) es una forma válida de Ransack que Bali no emite: llegaba
  # a `to_unsafe_h` como Array y devolvía un 500 en cualquier index desde una URL a mano.
  # Normalizarla a la forma indexada la mete además DENTRO de la traducción de enums, en vez
  # de esquivarla y devolver los registros contrarios.
  def test_groupings_sent_as_an_array_are_normalized_and_cast
    form = EnumMovieFilterForm.new(@tenant.movies, params({ g: [ { status_in: [ "done" ], m: "and" } ] }))

    assert_equal 1, form.ransack_params[:g]["0"]["status_in"].first
    assert_equal [ @done.name ], form.result.pluck(:name)
  end

  # La normalización de la entrada solo alcanza al nivel de arriba, así que un `g` ANIDADO
  # todavía puede llegar como array: sin cubrirlo, el grupo interno esquiva la traducción.
  def test_enum_labels_are_cast_inside_a_nested_array_grouping
    filter_params = { g: { "0" => { g: [ { status_eq: "done" } ], m: "or" } } }
    form = EnumMovieFilterForm.new(@tenant.movies, params(filter_params))

    assert_equal 1, form.ransack_params[:g]["0"]["g"].first["status_eq"]
    assert_equal [ @done.name ], form.result.pluck(:name)
  end

  # Un grupo que no es un hash (`q[g][0]=x`, `q[g][]=x`) reventaba en Ransack: se descarta.
  def test_a_grouping_that_is_not_a_hash_is_discarded_instead_of_raising
    scalar = EnumMovieFilterForm.new(@tenant.movies, params({ g: { "0" => "x" } }))
    listed = EnumMovieFilterForm.new(@tenant.movies, params({ g: [ "x" ] }))

    assert_equal 2, scalar.result.count
    assert_equal 2, listed.result.count
  end

  def test_the_grouping_combinator_is_not_treated_as_an_attribute
    filter_params = { g: { "0" => { status_in: [ "done" ], m: "and" } }, m: "or" }
    form = EnumMovieFilterForm.new(@tenant.movies, params(filter_params))

    assert_equal "and", form.ransack_params[:g]["0"]["m"]
    assert_equal "or", form.ransack_params[:m]
  end

  # Fuera de la igualdad el valor no es una pertenencia: `_cont` pide un SUBSTRING y `_gteq`
  # un ORDEN sobre los códigos crudos. Traducir ahí cambiaría la pregunta.
  def test_only_equality_predicates_translate_enum_labels
    contains = EnumMovieFilterForm.new(@tenant.movies, params({ status_cont: "done" }))
    ordered = EnumMovieFilterForm.new(@tenant.movies, params({ status_gteq: "done" }))
    nulls = EnumMovieFilterForm.new(@tenant.movies, params({ g: { "0" => { status_null: "1" } } }))

    assert_equal "done", contains.ransack_params["status_cont"]
    assert_equal "done", ordered.ransack_params["status_gteq"]
    assert_equal "1", nulls.ransack_params[:g]["0"]["status_null"]
  end

  # @groupings es EL MISMO objeto que renderiza el popover y que viaja en el payload de una
  # vista guardada: castear en el lugar dejaría un `1` donde la UI espera "done".
  def test_casting_does_not_mutate_the_state_the_ui_renders
    form = EnumMovieFilterForm.new(@tenant.movies, params({ g: { "0" => { status_in: [ "done" ], m: "and" } } }))

    form.ransack_params

    assert_equal [ "done" ], form.filter_groups.first[:conditions].first[:value]
    assert_equal [ "done" ], form.current_view_payload["groupings"]["0"]["status_in"]
  end

  # Un enum de string nunca estuvo roto: traducir ahí produce el MISMO SQL, así que la
  # traducción es idempotente y no un cambio de comportamiento.
  def test_a_string_enum_label_maps_to_its_value
    action = StringEnumMovie.create!(name: "Mad Max", genre: :action, tenant_id: @tenant.id)
    StringEnumMovie.create!(name: "Airplane!", genre: :comedy, tenant_id: @tenant.id)

    by_label = Bali::FilterForm.new(StringEnumMovie.all, params({ g: { "0" => { genre_eq: "action" } } }))
    by_value = Bali::FilterForm.new(StringEnumMovie.all, params({ g: { "0" => { genre_eq: "Action" } } }))

    assert_equal "Action", by_label.ransack_params[:g]["0"]["genre_eq"]
    assert_equal "Action", by_value.ransack_params[:g]["0"]["genre_eq"]
    # Afirmar el set y no la igualdad entre los dos: los dos caminos se rompen JUNTOS, así que
    # comparar uno con otro pasa igual de bien con ambos vacíos.
    assert_equal [ action.name ], by_label.result.pluck(:name)
    assert_equal [ action.name ], by_value.result.pluck(:name)
  end

  def test_compound_predicates_translate_every_member
    filter_params = { g: { "0" => { status_eq_any: %w[done draft] } } }
    form = EnumMovieFilterForm.new(@tenant.movies, params(filter_params))

    assert_equal [ 1, 0 ], form.ransack_params[:g]["0"]["status_eq_any"]
  end

  # Los tests del repo usan dobles como scope. Sin `defined_enums` no hay nada que traducir y
  # el módulo es un no-op: no puede reventar. No se llama a #result — eso sería `[].ransack`.
  def test_a_scope_without_a_model_does_not_raise
    form = Bali::FilterForm.new([], params({ g: { "0" => { status_eq: "done" } } }))

    assert_equal "done", form.ransack_params[:g]["0"]["status_eq"]
  end

  # Anti-drift: los predicados que traducimos son EXACTAMENTE los que la UI de select ofrece.
  # Si alguien agrega un operador al select, esto falla y fuerza la decisión.
  def test_the_translated_predicates_are_the_ones_the_select_ui_offers
    assert_equal Bali::Filters::Operators.for_type(:select).pluck(:value).sort,
                 Bali::FilterForm::EnumCasting::EQUALITY_PREDICATES.sort
  end
end
