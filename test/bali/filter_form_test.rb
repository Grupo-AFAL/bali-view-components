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

# The listing that reported #852: quick search and simple filters on the same form, which is
# where the two "state" mechanisms (persistence and saved views) cross. The options are spelled
# the same as the column value so assertions can be about the narrowing itself.
class SearchableSimpleFilterForm < Bali::FilterForm
  search_fields :name, :genre

  filter_attribute :genre, type: :select, simple: true, advanced: false,
                   options: [ %w[Action Action], %w[Comedy Comedy] ], blank: "All Genres"
end

# The form from #966: a date_range declared as an `attribute`. `result` applies it OUTSIDE
# Ransack, so `query_params` excludes it by construction — but the filter IS narrowing the
# listing, and `active_filters` has to say so.
class DateRangeAttributeFilterForm < Bali::FilterForm
  attribute :name_cont
  attribute :created_at, Bali::Types::DateRangeValue.new
end

# The form from #1017: `search_fields` AND the predicate declared as an attribute — the shape a
# listing takes when its quick search also takes part in the advanced filters. The term travels
# through two doors (`search_value` and the attribute of the same name) and clearing it has to
# close both; `genre_eq` is here to pin that the X does not take the rest of the narrowing.
class DualChannelSearchFilterForm < Bali::FilterForm
  search_fields :name, :genre

  attribute :name_or_genre_cont
  attribute :genre_eq
end

# Test form with the full search_fields signature (#982): aria_label: is the
# box's aria-label — the only accessible name that survives typing — and
# width: the per-listing width override. Both were renderable by the
# components but unreachable from the DSL. (`label:` was the beta spelling and
# now raises — see the rename tests below, #1026.)
class LabelledSearchMovieFilterForm < Bali::FilterForm
  search_fields :name, icon: "search", aria_label: "Search movies", width: "w-64"

  filter_attribute :name, type: :text
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

# The #882 case written with the API v3 promotes: a filter whose control already names itself
# through its blank option, declared with `label: false` so it carries no caption.
class UncaptionedSimpleFilterForm < Bali::FilterForm
  filter_attribute :genre, type: :select, simple: true, advanced: false,
                   options: [ %w[Action action] ],
                   blank: "Todos los géneros",
                   label: false
end

# #1155: no caption, but named. `aria_label:` is the explicit override of the string that
# resolves the control's accessible name.
class AriaLabelledSimpleFilterForm < Bali::FilterForm
  filter_attribute :year, type: :select, simple: true, advanced: false,
                   options: [ %w[2026 2026] ],
                   label: false,
                   aria_label: "Año fiscal"
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

# Enum-label casting (#670): the select's options are the enum LABELS, which is what
# `Movie.statuses.keys` yields — the case Ransack broke by casting with the column's raw
# type.
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

# A STRING enum: never broken (Ransack does not destroy the label and the EnumType resolves it
# afterwards). It is here to pin that the translation is IDEMPOTENT, not a change of
# behaviour.
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

  # What the advanced panel sends: `q[g][N][attr_pred]`.
  def grouped_params(groups)
    ActionController::Parameters.new(q: { g: groups.transform_keys(&:to_s) })
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

  # #1085 — the fourth source. The advanced panel's conditions travel nested
  # (`q[g][N][attr_pred]`), not flat under `q`, so `active_filters` cannot see them by
  # construction: `Table` painted its no-records empty state over a whole catalogue the panel
  # had narrowed to zero.
  def test_active_filters_counts_a_condition_of_the_advanced_panel
    @form = MovieFilterForm.new(@tenant.movies, grouped_params(0 => { name_cont: "Iron" }))

    assert(@form.active_filters?)
    assert_equal(1, @form.active_filters_count)
  end

  def test_active_filters_counts_every_condition_across_groups
    @form = MovieFilterForm.new(
      @tenant.movies,
      grouped_params(0 => { name_cont: "Iron", genre_eq: "Action" }, 1 => { name_cont: "Man" })
    )

    assert_equal(3, @form.active_filters_count)
  end

  def test_active_filters_adds_the_advanced_panel_to_the_flat_half
    @form = MovieFilterForm.new(@tenant.movies,
                                params({ name_i_cont: "Iron" }).tap { |p|
                                  p[:q][:g] = { "0" => { genre_eq: "Action" } }
                                })

    assert_equal(2, @form.active_filters_count)
  end

  # A builder row with no value narrows nothing, and a `between` with both ends blank does not
  # either: it is a Hash, so it passes `present?` without contributing a single pair to the query.
  # Same rule that decides what TRAVELS — see the equivalence test further down.
  def test_active_filters_ignores_an_empty_condition_of_the_advanced_panel
    @form = MovieFilterForm.new(@tenant.movies, grouped_params(0 => { name_cont: "" }))

    refute(@form.active_filters?)
    assert_equal(0, @form.active_filters_count)
  end

  def test_active_filters_ignores_a_between_with_both_ends_blank
    @form = MovieFilterForm.new(
      @tenant.movies, grouped_params(0 => { created_at_gteq: "", created_at_lteq: "" })
    )

    refute(@form.active_filters?)
  end

  # What is COUNTED and what TRAVELS have to be the same question: if they diverge, a bulk action
  # acts on a different set than the listing says it is showing.
  def test_what_counts_as_applied_is_what_travels
    [
      { name_cont: "Iron" },
      { name_cont: "" },
      { created_at_gteq: "", created_at_lteq: "" },
      { created_at_gteq: "2026-01-01", created_at_lteq: "" }
    ].each do |conditions|
      form = MovieFilterForm.new(@tenant.movies, grouped_params(0 => conditions))
      travels = Bali::Filters::ActiveFilterParams.group_pairs(form.filter_groups).any?

      assert_equal(travels, form.applied_filter_conditions.any?, conditions.inspect)
    end
  end

  # The hash is still ONLY the flat half, and has to stay that way: it is re-emitted as `q[...]`
  # pairs, so a group condition folded in there would go out twice —flat and nested— and the bulk
  # would send a filter the listing never applied.
  def test_the_flat_hash_does_not_absorb_the_advanced_panel
    @form = MovieFilterForm.new(@tenant.movies, grouped_params(0 => { name_cont: "Iron" }))

    assert_empty(@form.active_filters)
    assert_equal(
      [ [ "q[g][0][m]", "and" ], [ "q[g][0][name_cont]", "Iron" ] ],
      Bali::Filters::ActiveFilterParams.for_filter_form(@form)
    )
  end

  # `s` is Ransack's sort param. Sorting is not narrowing.
  def test_active_filters_ignores_the_sort_param
    @form = MovieFilterForm.new(@tenant.movies, params({ s: "name asc" }))
    refute(@form.active_filters?)
  end

  # #966 — a date_range declared as an `attribute` does not go through Ransack (`result` applies
  # it separately, with a `where` on the relation) and `query_params` excludes it by construction.
  # `active_filters` has to include it anyway: the badge, `Table`'s empty state and the bulk's
  # re-emission all read here, and without it the filter narrows the listing but "does not exist"
  # for anyone — the bulk would act on a superset of what is on screen.
  def test_active_filters_includes_a_date_range_declared_as_attribute
    @form = DateRangeAttributeFilterForm.new(
      Movie.all, params({ created_at: "2026-01-01..2026-12-31", name_cont: "Iron" })
    )

    assert_equal(2, @form.active_filters_count)
    assert_includes(@form.active_filters.keys, "created_at")
  end

  # It travels RESOLVED (`start..end`), which is the shape `DateRangeValue` casts again: the pair a
  # form re-emits as hidden fields has to reproduce the same narrowing.
  def test_an_active_date_range_attribute_round_trips_through_its_own_cast
    @form = DateRangeAttributeFilterForm.new(
      Movie.all, params({ created_at: "2026-01-01..2026-12-31" })
    )

    reparsed = Bali::Types::DateRangeValue.new.cast(@form.active_filters["created_at"])
    assert_equal(Time.zone.parse("2026-01-01"), reparsed.begin)
    assert_equal(Time.zone.parse("2026-12-31"), reparsed.end)
  end

  def test_active_filters_skips_a_blank_date_range_attribute
    @form = DateRangeAttributeFilterForm.new(Movie.all, params({ name_cont: "Iron" }))

    assert_equal({ "name_cont" => "Iron" }, @form.active_filters)
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

  def test_combinator_collapses_a_value_that_is_not_a_combinator
    filter_params = { m: '"><img src=x onerror=alert(1)>' }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    assert_equal("and", @form.combinator)
    assert_nil(@form.applied_combinator)
  end

  def test_group_combinator_collapses_a_value_that_is_not_a_combinator
    filter_params = { g: { "0" => { name_cont: "Iron", m: "<script>alert(1)</script>" } } }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    assert_equal("and", @form.filter_groups.first[:combinator])
  end

  # A group with no `m` is what Ransack ANDs (`Nodes::Grouping` with a nil combinator),
  # so the panel has to say AND for it. It used to say OR — the seed every new group was
  # born with — while the listing was already the intersection (#1121).
  def test_a_group_without_a_combinator_parses_as_and_which_is_what_ransack_applies
    filter_params = { g: { "0" => { name_cont: "Iron", genre_eq: "action" } } }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    assert_equal("and", @form.filter_groups.first[:combinator])
  end

  def test_a_group_that_chose_or_keeps_it
    filter_params = { g: { "0" => { name_cont: "Iron", genre_eq: "action", m: "or" } } }
    @form = AdvancedMovieFilterForm.new(Movie.all, params(filter_params))
    assert_equal("or", @form.filter_groups.first[:combinator])
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

  # --- search_fields label:/width: (#982) ---

  def test_search_fields_dsl_stores_label_and_width
    assert_equal("Search movies", LabelledSearchMovieFilterForm.defined_search_label)
    assert_equal("w-64", LabelledSearchMovieFilterForm.defined_search_width)
  end

  # The producer emits every key the components render: a key search_config
  # cannot emit is an option the auto-configured route cannot express, which is
  # how the search box lost its aria-label on every bare `with_simple_filters`.
  def test_search_config_emits_every_search_config_key
    @form = LabelledSearchMovieFilterForm.new(Movie.all, params({}))
    config = @form.search_config
    assert_equal(Bali::SearchConfig::KEYS.sort, config.keys.sort)
    assert_equal("Search movies", config[:label])
    assert_equal("w-64", config[:width])
    assert_equal("search", config[:icon])
  end

  def test_search_aria_label_and_width_instance_kwargs_override_the_dsl
    @form = LabelledSearchMovieFilterForm.new(Movie.all, params({}),
                                              search_aria_label: "Find", search_width: "w-96")
    assert_equal("Find", @form.search_label)
    assert_equal("w-96", @form.search_width)
  end

  # --- the #1026 rename: the beta spellings raise, naming their replacement ---

  def test_search_fields_label_keyword_raises_naming_aria_label
    error = assert_raises(ArgumentError) do
      Class.new(Bali::FilterForm) do
        def self.name = "RenamedForm"
        search_fields :name, label: "Search"
      end
    end
    assert_match(/`label:` was renamed to `aria_label:`/, error.message)
  end

  def test_search_label_initialize_kwarg_raises_naming_search_aria_label
    error = assert_raises(ArgumentError) do
      LabelledSearchMovieFilterForm.new(Movie.all, params({}), search_label: "Find")
    end
    assert_match(/`search_label:` was renamed to `search_aria_label:`/, error.message)
  end

  def test_search_label_and_width_are_inherited_by_subclasses
    subclass = Class.new(LabelledSearchMovieFilterForm)
    assert_equal("Search movies", subclass.defined_search_label)
    assert_equal("w-64", subclass.defined_search_width)
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

  # --- Persistence covers the grouping too ---

  def test_persists_and_restores_the_active_group_by
    # Without group_by in the cache, coming back to the listing restored the filters but lost the
    # grouping — and a saved view that groups stopped being recognised as active.
    grouped = ActionController::Parameters.new(q: { genre_eq: "action" }, group_by: "genre")
    GroupableMovieFilterForm.new(Movie.all, grouped, storage_id: "movies")

    stored = Rails.cache.read(cache_key_for(GroupableMovieFilterForm))
    assert_equal("genre", stored[:group_by].to_s)

    restored = GroupableMovieFilterForm.new(Movie.all, ActionController::Parameters.new,
                                            storage_id: "movies", persist_enabled: true)
    assert_equal("genre", restored.group_by.to_s)
  end

  def test_persists_the_group_by_even_while_it_is_suspended
    # Suspension outside table mode is a DERIVED predicate, never `@group_by = nil`: nulling the
    # ivar poisoned the cache with nil when the listing was entered in card mode, and coming back
    # to the table no longer found the grouping.
    suspended = ActionController::Parameters.new(
      q: { genre_eq: "action" }, group_by: "genre", view: "grid"
    )
    form = GroupableMovieFilterForm.new(Movie.all, suspended, storage_id: "movies")
    assert(form.group_by_suspended?)

    stored = Rails.cache.read(cache_key_for(GroupableMovieFilterForm))
    assert_equal("genre", stored[:group_by].to_s)
  end

  def test_a_group_by_from_the_url_beats_the_persisted_one
    # Choosing a grouping arrives as `?group_by=` ALONE: the filters live in the cache, so the URL
    # does not carry them and the restore branch runs, overwriting the click just made with the old
    # grouping. The control did nothing and the cards↔table round trip lost it.
    GroupableMovieFilterForm.new(Movie.all, params(genre_eq: "action"), storage_id: "movies")
    assert_nil(Rails.cache.read(cache_key_for(GroupableMovieFilterForm))[:group_by])

    clicked = GroupableMovieFilterForm.new(
      Movie.all, ActionController::Parameters.new(group_by: "genre"),
      storage_id: "movies", persist_enabled: true
    )
    assert_equal(:genre, clicked.group_by)
  end

  # The state that is RENDERED and the state that is STORED have to be the same one, or the cache
  # ends up telling another story: the click arrives WITHOUT `q` (the filters already live in the
  # cache), the restore branch runs, and rendering the new choice without writing it left that one
  # render right and the next request, param-less, resurrecting the old grouping.
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

  # With no previous filters there is nothing in the cache, and choosing a grouping did not write
  # anything either: the choice lasted a single render.
  def test_a_group_by_chosen_without_any_stored_state_is_persisted
    GroupableMovieFilterForm.new(Movie.all, ActionController::Parameters.new(group_by: "genre"),
                                 storage_id: "movies", persist_enabled: true)

    returning = GroupableMovieFilterForm.new(Movie.all, ActionController::Parameters.new,
                                             storage_id: "movies", persist_enabled: true)
    assert_equal(:genre, returning.group_by)
  end

  def test_turning_the_grouping_off_is_not_undone_by_the_persisted_one
    # An empty `?group_by=` means "no grouping", and has to be distinguishable from "nothing
    # arrived": with persistence on, a missing param means restore the cache — so turning the
    # grouping off resurrected it in the same render.
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
    # With persistence off the user asked the server NOT to hand state back: clearing the search
    # cannot be the back door filters reappear through.
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

  def test_clearing_the_search_also_clears_a_predicate_declared_as_an_attribute
    # The term comes in through two doors and the X closed only one, leaving the box empty over a
    # listing still narrowed by it (#1017).
    DualChannelSearchFilterForm.new(
      Movie.all, params(name_or_genre_cont: "iron"), storage_id: "movies"
    )

    cleared = DualChannelSearchFilterForm.new(
      Movie.all, ActionController::Parameters.new(clear_search: true),
      storage_id: "movies", persist_enabled: true
    )
    assert_nil(cleared.search_value)
    assert_nil(cleared.name_or_genre_cont)
  end

  def test_a_cleared_search_does_not_come_back_on_the_next_visit
    # What actually hurt: the cache was rewritten WITH the predicate inside, so the narrowing came
    # back on every clean visit, by then with no visible term to explain it.
    DualChannelSearchFilterForm.new(
      Movie.all, params(name_or_genre_cont: "iron"), storage_id: "movies"
    )
    DualChannelSearchFilterForm.new(
      Movie.all, ActionController::Parameters.new(clear_search: true),
      storage_id: "movies", persist_enabled: true
    )

    revisited = DualChannelSearchFilterForm.new(
      Movie.all, ActionController::Parameters.new,
      storage_id: "movies", persist_enabled: true
    )
    assert_nil(revisited.name_or_genre_cont)
    assert_nil(revisited.search_value)
  end

  def test_clearing_the_search_keeps_the_other_filters
    DualChannelSearchFilterForm.new(
      Movie.all, params(name_or_genre_cont: "iron", genre_eq: "action"), storage_id: "movies"
    )

    cleared = DualChannelSearchFilterForm.new(
      Movie.all, ActionController::Parameters.new(clear_search: true),
      storage_id: "movies", persist_enabled: true
    )
    assert_nil(cleared.name_or_genre_cont)
    assert_equal("action", cleared.genre_eq)
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

  # Regression: a "blank" saved view (show everything) applied with persist_enabled: true must not
  # lose to the previous visit's cache — a view is a complete state, and that includes the empty
  # state. Before the fix, has_filter_params did not tell "no view arrived" from "a blank view
  # arrived" and both fell to the restore branch.
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

  # --- #852: persistence covers the simple filters, same as saved views ---
  #
  # The "Recordar filtros" checkbox was not dead —it governs the quick search— and that made it
  # worse: the user came back to the listing and the search was there, but their selects were not.
  # A saved view ON THE SAME LISTING did restore them (`PAYLOAD_KEYS` includes them), so the same
  # component held two definitions of "the filters' state".

  def test_persists_and_restores_an_active_simple_filter
    SearchableSimpleFilterForm.new(Movie.all, params(genre_eq: "Action"), storage_id: "movies")

    stored = Rails.cache.read(cache_key_for(SearchableSimpleFilterForm))
    assert_equal({ "genre_eq" => "Action" }, stored[:simple_filters])

    restored = SearchableSimpleFilterForm.new(
      Movie.all, ActionController::Parameters.new, storage_id: "movies", persist_enabled: true
    )
    assert_equal({ "genre_eq" => "Action" }, restored.active_simple_filters)
    assert_equal("Action", restored.ransack_params["genre_eq"],
                 "restaurar tiene que llegar hasta Ransack, no solo pintar el select")
  end

  def test_a_restored_simple_filter_narrows_the_result
    tenant = Tenant.create(name: "Restore Studio")
    tenant.movies.create(name: "Iron Man", genre: "Action")
    tenant.movies.create(name: "Snatch", genre: "Comedy")

    SearchableSimpleFilterForm.new(Movie.all, params(genre_eq: "Action"), storage_id: "movies")
    restored = SearchableSimpleFilterForm.new(
      Movie.all, ActionController::Parameters.new, storage_id: "movies", persist_enabled: true
    )

    names = restored.result.pluck(:name)
    assert_includes(names, "Iron Man")
    refute_includes(names, "Snatch")
  end

  def test_a_simple_filter_is_not_restored_when_persistence_is_off
    # The checkbox governs: if restoring happened while it is off, the fix would have changed what
    # the checkbox means instead of widening what it covers.
    SearchableSimpleFilterForm.new(Movie.all, params(genre_eq: "Action"), storage_id: "movies")

    restored = SearchableSimpleFilterForm.new(
      Movie.all, ActionController::Parameters.new, storage_id: "movies", persist_enabled: false
    )
    assert_empty(restored.active_simple_filters)
  end

  def test_a_simple_filter_from_the_url_beats_the_persisted_state
    # The other half, and the worse one: because `has_filter_params` did not count the simple ones,
    # a URL asking only for one fell into the RESTORE branch and the cache beat the URL.
    # Measured on /admin/studios over `?q[country_eq]=USA`: 9 rows with the persistence
    # cookie at 1 —a stored search the URL never mentions sneaking in— against 10 with
    # the cookie at 0. A shared link rendered differently depending on a cookie of whoever opened it.
    SearchableSimpleFilterForm.new(Movie.all, params(name_or_genre_cont: "iron"), storage_id: "movies")

    deep_link = SearchableSimpleFilterForm.new(
      Movie.all, params(genre_eq: "Action"), storage_id: "movies", persist_enabled: true
    )
    assert_nil(deep_link.search_value, "la URL manda: no puede colarse una búsqueda que no nombra")
    assert_equal({ "genre_eq" => "Action" }, deep_link.active_simple_filters)
  end

  def test_clearing_a_simple_filter_is_not_undone_by_the_persisted_one
    # The SimpleFilters form submits ALL of its controls, so emptying the select arrives as
    # `q[genre_eq]=`: empty value, explicit choice. Without telling that from "nothing arrived"
    # —the same distinction `@group_by_requested` makes— restoring handed the user back the
    # filter they had just cleared.
    SearchableSimpleFilterForm.new(Movie.all, params(genre_eq: "Action"), storage_id: "movies")

    cleared = SearchableSimpleFilterForm.new(
      Movie.all, params(genre_eq: ""), storage_id: "movies", persist_enabled: true
    )
    assert_empty(cleared.active_simple_filters)

    returning = SearchableSimpleFilterForm.new(
      Movie.all, ActionController::Parameters.new, storage_id: "movies", persist_enabled: true
    )
    assert_empty(returning.active_simple_filters, "limpiar tiene que sobrevivir al próximo request")
  end

  def test_clearing_the_search_keeps_the_simple_filters
    # `clearSearch` navigates dropping ALL the `q[...]` (see preservedParamsUrl), so the cache is
    # the only source of what had been chosen: if the merge or the tuple drops them, clearing the
    # search clears the selects too.
    SearchableSimpleFilterForm.new(
      Movie.all, params(genre_eq: "Action", name_or_genre_cont: "iron"), storage_id: "movies"
    )

    cleared = SearchableSimpleFilterForm.new(
      Movie.all, ActionController::Parameters.new(clear_search: true),
      storage_id: "movies", persist_enabled: true
    )
    assert_nil(cleared.search_value)
    assert_equal({ "genre_eq" => "Action" }, cleared.active_simple_filters)

    stored = Rails.cache.read(cache_key_for(SearchableSimpleFilterForm))
    assert_equal({ "genre_eq" => "Action" }, stored[:simple_filters],
                 "y tienen que sobrevivir al merge que anula la búsqueda")
  end

  def test_a_form_without_simple_filters_stores_an_empty_simple_filter_state
    # The payload grows for everyone, and the restore branch reads it unconditionally: a form with
    # no simple filters cannot be left reading a key that was never written.
    SearchableMovieFilterForm.new(
      Movie.all, params(name_or_genre_or_tenant_name_cont: "Iron"), storage_id: "movies"
    )

    stored = Rails.cache.read(cache_key_for(SearchableMovieFilterForm))
    assert_empty(stored[:simple_filters])

    restored = SearchableMovieFilterForm.new(Movie.all, params({}), storage_id: "movies",
                                             persist_enabled: true)
    assert_equal("Iron", restored.search_value)
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

  # `label: false` means "I want no caption". The distinction did not exist before: `nil` and
  # `false` are both falsy, so the `||` sent both to the derivation and there was no way to ask for
  # a filter without one. The template already knew not to paint it.
  def test_simple_filters_config_honours_an_explicit_label_false
    form = Bali::FilterForm.new(
      Movie.all, params({}),
      simple_filters: [ { attribute: :genre, collection: [ %w[A a] ], blank: "All", label: false } ]
    )

    assert_nil(form.simple_filters_config.first[:label])
  end

  def test_simple_filters_config_still_infers_when_no_label_is_given
    form = Bali::FilterForm.new(
      Movie.all, params({}),
      simple_filters: [ { attribute: :genre, collection: [ %w[A a] ], blank: "All" } ]
    )

    assert_equal("Genre", form.simple_filters_config.first[:label])
  end

  # The same case through the API v3 promotes, `filter_attribute`, which is how it will arrive from a
  # host.
  def test_filter_attribute_honours_an_explicit_label_false_for_the_simple_row
    form = UncaptionedSimpleFilterForm.new(Movie.all, params({}))

    assert_nil(form.simple_filters_config.first[:label])
    assert_equal("Todos los géneros", form.simple_filters_config.first[:blank])
  end

  # #1155. `label: false` promised "the control already names itself with its blank option", and
  # that was false: the blank option's text is the SELECTED VALUE, not the name. `aria_label:` is
  # how to name it without painting a caption, spelled the same as `search_fields aria_label:`
  # (#1026).
  def test_filter_attribute_accepts_an_aria_label_for_the_simple_row
    form = AriaLabelledSimpleFilterForm.new(Movie.all, params({}))
    config = form.simple_filters_config.first

    assert_nil(config[:label])
    assert_equal("Año fiscal", config[:aria_label])
  end

  # Instance-level hashes do not go through the DSL, so the key is copied here too.
  def test_an_instance_level_simple_filter_hash_carries_aria_label
    form = Bali::FilterForm.new(
      Movie.all, params({}),
      simple_filters: [ { attribute: :genre, collection: [ %w[A a] ], blank: "All",
                          label: false, aria_label: "Género" } ]
    )

    assert_equal("Género", form.simple_filters_config.first[:aria_label])
  end

  # Same as `label:` and `blank:`: a zero-arity proc, for a translation that cannot be frozen at
  # class-load time.
  def test_an_aria_label_proc_is_resolved_per_instance
    form = Bali::FilterForm.new(
      Movie.all, params({}),
      simple_filters: [ { attribute: :genre, collection: [ %w[A a] ], label: false,
                          aria_label: -> { "Género #{1 + 1}" } } ]
    )

    assert_equal("Género 2", form.simple_filters_config.first[:aria_label])
  end

  # The sentinel CANNOT be the absence of the key: `simple_filter` delegates to
  # `filter_attribute`, which always stores `explicit_label:`, so `defined_simple_filters` hands
  # the `:label` key back set even when nobody wrote it. With `key?` as the condition, EVERY
  # filter declared through the DSL would end up with no caption.
  def test_the_dsl_always_carries_the_label_key_so_key_presence_cannot_be_the_sentinel
    genre = SimpleFilterableMovieFilterForm.defined_simple_filters
                                           .find { |f| f[:attribute] == :genre }

    assert(genre.key?(:label), "la clave viene puesta")
    assert_nil(genre[:label], "y sin valor, porque el DSL no recibió ninguno")
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

  # `view:` is the display mode exactly as it arrives from the URL; `extra` is how the
  # `view_param:` tests spell that param under another name.
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

  # --- Suspension outside table mode: the STATE survives, the APPLICATION switches off ---
  #
  # A table is the only surface where a group band means anything. In cards the same ordering
  # reshuffled the content with nothing on screen to explain it, so there the grouping is
  # SUSPENDED — but the param has to survive, or coming back to the table no longer finds it.

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

    # STATE: intact — it is what the filters form's hidden field preserves.
    assert_equal(:genre, form.group_by)
    assert(form.group_by_active?)
    # MODE and APPLICATION: off.
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
    # The case of the vast majority of listings: with no `?view=` in the URL there is no mode that
    # could suspend anything.
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
    # `[]` is NOT "nobody told me": it is the host declaring that no mode applies the grouping (it
    # wants the param preserved and saved in a view, never applied). Collapsing it to the default
    # handed it exactly the opposite, silently.
    never = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "table"),
                                         group_by_modes: [])

    assert(never.group_by_active?)
    refute(never.group_by_applies?)
    assert_nil(never.group_by_applied)
    assert_nil(never.ransack_params["s"])

    # And not through the back door either: with no `?view=`, the "no mode applies it" escape would
    # have turned it back on.
    bare = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre"), group_by_modes: [])
    refute(bare.group_by_applies?)
  end

  def test_display_mode_from_the_host_beats_the_url
    # A listing whose default view is not the table lands WITHOUT `?view=`, and the form —which
    # only looks at the URL— took for granted that it applied: the cards came back ordered by group
    # with no band to explain it.
    cards = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre"), display_mode: :grid)

    assert_equal(:grid, cards.display_mode)
    assert(cards.group_by_suspended?)
    assert_nil(cards.ransack_params["s"])

    # With the mode in the URL the host still wins: it is the only one that knows what it renders.
    forced = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "table"),
                                          display_mode: :grid)
    assert(forced.group_by_suspended?)
  end

  def test_view_param_selects_which_param_carries_the_display_mode
    custom = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", modo: "grid"),
                                          view_param: :modo)
    assert(custom.group_by_suspended?)

    # `view` is no longer the param this form looks at, so it suspends nothing.
    ignored = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "grid"),
                                           view_param: :modo)
    assert(ignored.group_by_applied?)
  end

  def test_a_view_saved_from_cards_still_carries_the_suspended_grouping
    form = GroupableMovieFilterForm.new(@tenant.movies, group_params("genre", view: "grid"))
    # String and not Symbol: this payload is compared against one that has already come back from a
    # jsonb, where everything is String, and `comparable_view_state` normalises keys but not values.
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

  # --- auto_submit (#725) ---

  def test_auto_submit_reaches_the_simple_filters_config
    form_class = Class.new(Bali::FilterForm) do
      filter_attribute :status, type: :select, simple: true, advanced: false,
                       options: [ %w[Draft draft], %w[Published published] ],
                       input: :radio_group, auto_submit: true
      filter_attribute :genre, type: :select, simple: true, advanced: false,
                       options: [ %w[Action action] ]
    end

    by_attribute = form_class.new(Movie.all, params({})).simple_filters_config.index_by { |f| f[:attribute] }

    assert_equal(true, by_attribute[:status][:auto_submit])
    assert_equal(false, by_attribute[:genre][:auto_submit])
  end

  # The default is false and not nil: a row declared before the option existed cannot be left
  # depending on the template reading a nil as false.
  def test_auto_submit_defaults_to_false
    status = SimpleFilterableMovieFilterForm.filter_attributes.find { |a| a[:key] == :status }

    assert_equal(false, status[:auto_submit])
  end

  # #996: a native select is a finished choice too — the change fires when the menu closes on a
  # selection — so it can auto-submit just like the pills.
  def test_auto_submit_on_a_select_reaches_the_simple_filters_config
    form_class = Class.new(Bali::FilterForm) do
      filter_attribute :genre, type: :select, simple: true, advanced: false,
                       options: [ %w[Action action] ], auto_submit: true
    end

    genre = form_class.new(Movie.all, params({})).simple_filters_config.first
    assert_equal(true, genre[:auto_submit])
  end

  # It fails when the class is defined and not at render time, like an unknown `input:`: an
  # `auto_submit:` nobody reads is worse than an error.
  def test_auto_submit_outside_the_single_choice_widgets_raises
    error = assert_raises(ArgumentError) do
      Class.new(Bali::FilterForm) do
        filter_attribute :created_at, type: :date, simple: true, auto_submit: true
      end
    end
    assert_match(/auto_submit: true only applies to single-choice widgets/, error.message)
    assert_match(/this one is :date/, error.message)
  end

  def test_auto_submit_on_an_advanced_only_attribute_raises
    error = assert_raises(ArgumentError) do
      Class.new(Bali::FilterForm) { filter_attribute :name, type: :text, auto_submit: true }
    end
    assert_match(/not a simple filter/, error.message)
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

  # --- Saved views (B2): named filter combinations through saved_views_store ---

  # Fake store fulfilling the SavedViewsConfiguration contract (list/find/save/delete).
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
    # The view REPLACES the state — whatever came in q does not survive.
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

  # A view is a COMPLETE state, not a merge: the same contract that already governs `attributes`. An
  # old payload, saved before the key existed, clears.
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

# Enum-label casting (#670). Symptom: filtering Status = "Done" returned exactly the opposite
# records. Cause: Ransack casts with the column's RAW type, so over an integer enum "done".to_i is
# 0 — the value of `draft`.
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

  # THE reproduction: the exact shape Bali::Filters' builder emits. It asserts on the SET and not
  # on the count — with two records, a count of 1 passes just as well while filtering by the wrong
  # status.
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

  # NEGATED predicates are where a broken translation is invisible: the negation returns the
  # COMPLEMENT, a plausible and non-empty set. Hence asserting the set, not the param.
  def test_a_negated_enum_label_filters_by_the_right_records
    excluded = EnumMovieFilterForm.new(@tenant.movies, params({ g: { "0" => { status_not_in: [ "done" ] } } }))
    different = EnumMovieFilterForm.new(@tenant.movies, params({ status_not_eq: "done" }))

    assert_equal [ "draft" ], excluded.result.pluck(:status).uniq
    assert_equal [ "draft" ], different.result.pluck(:status).uniq
  end

  # A known RAW value passes through intact: an app already sending 0/1 keeps working as before.
  def test_a_raw_enum_value_is_left_alone
    raw = EnumMovieFilterForm.new(@tenant.movies, params({ status_eq: "1" }))

    assert_equal "1", raw.ransack_params["status_eq"]
    assert_equal [ "done" ], raw.result.pluck(:status).uniq
  end

  # A value that is NEITHER a label NOR a raw value cannot pass through intact: Ransack casts it
  # with the column's raw type and `"Done".to_i` is 0, i.e. the FIRST member of the enum — the
  # original bug, back, inverted and silent. The sentinel makes equality return nothing and the
  # negation return everything, which is the honest answer.
  def test_a_value_that_is_neither_a_label_nor_a_raw_value_matches_nothing
    humanized = EnumMovieFilterForm.new(@tenant.movies, params({ status_eq: "Done" }))
    renamed = EnumMovieFilterForm.new(@tenant.movies, params({ g: { "0" => { status_in: [ "completed" ] } } }))
    negated = EnumMovieFilterForm.new(@tenant.movies, params({ status_not_eq: "completed" }))

    assert_empty humanized.result
    assert_empty renamed.result
    assert_equal %w[done draft].sort, negated.result.pluck(:status).sort
  end

  # Ransack ignores blank conditions: mapping the empty value would turn an unchosen select into
  # "show nothing" — trading a wrong-data bug for another one.
  def test_a_blank_value_does_not_filter
    form = EnumMovieFilterForm.new(@tenant.movies, params({ status_eq: "" }))

    assert_equal %w[done draft].sort, form.result.pluck(:status).sort
  end

  # `FilterForm.new(Movie, params)` —the form Ransack's own API teaches— does not respond to
  # `model`: asking there made the whole translation a silent no-op and the filter returned the
  # opposite records, without a single signal.
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
    # Ransack DISCARDS a condition it does not understand without raising anything, so the param
    # alone does not tell "filtered right" from "dropped the condition and returned everything".
    assert_equal [ @done.name ], form.result.pluck(:name)
  end

  # `q[g][]` (groupings as an ARRAY) is a valid Ransack shape Bali does not emit: it reached
  # `to_unsafe_h` as an Array and returned a 500 on any index from a hand-written URL. Normalising
  # it to the indexed shape also brings it INSIDE the enum translation, instead of dodging it and
  # returning the opposite records.
  def test_groupings_sent_as_an_array_are_normalized_and_cast
    form = EnumMovieFilterForm.new(@tenant.movies, params({ g: [ { status_in: [ "done" ], m: "and" } ] }))

    assert_equal 1, form.ransack_params[:g]["0"]["status_in"].first
    assert_equal [ @done.name ], form.result.pluck(:name)
  end

  # Input normalisation only reaches the top level, so a NESTED `g` can still arrive as an array:
  # without covering it, the inner group dodges the translation.
  def test_enum_labels_are_cast_inside_a_nested_array_grouping
    filter_params = { g: { "0" => { g: [ { status_eq: "done" } ], m: "or" } } }
    form = EnumMovieFilterForm.new(@tenant.movies, params(filter_params))

    assert_equal 1, form.ransack_params[:g]["0"]["g"].first["status_eq"]
    assert_equal [ @done.name ], form.result.pluck(:name)
  end

  # A grouping that is not a hash (`q[g][0]=x`, `q[g][]=x`) blew up in Ransack: it is discarded.
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

  # Outside equality the value is not a membership: `_cont` asks for a SUBSTRING and `_gteq` for an
  # ORDER over the raw codes. Translating there would change the question.
  def test_only_equality_predicates_translate_enum_labels
    contains = EnumMovieFilterForm.new(@tenant.movies, params({ status_cont: "done" }))
    ordered = EnumMovieFilterForm.new(@tenant.movies, params({ status_gteq: "done" }))
    nulls = EnumMovieFilterForm.new(@tenant.movies, params({ g: { "0" => { status_null: "1" } } }))

    assert_equal "done", contains.ransack_params["status_cont"]
    assert_equal "done", ordered.ransack_params["status_gteq"]
    assert_equal "1", nulls.ransack_params[:g]["0"]["status_null"]
  end

  # @groupings is THE SAME object the popover renders and that travels in a saved view's payload:
  # casting in place would leave a `1` where the UI expects "done".
  def test_casting_does_not_mutate_the_state_the_ui_renders
    form = EnumMovieFilterForm.new(@tenant.movies, params({ g: { "0" => { status_in: [ "done" ], m: "and" } } }))

    form.ransack_params

    assert_equal [ "done" ], form.filter_groups.first[:conditions].first[:value]
    assert_equal [ "done" ], form.current_view_payload["groupings"]["0"]["status_in"]
  end

  # A string enum was never broken: translating there produces the SAME SQL, so the translation is
  # idempotent and not a change of behaviour.
  def test_a_string_enum_label_maps_to_its_value
    action = StringEnumMovie.create!(name: "Mad Max", genre: :action, tenant_id: @tenant.id)
    StringEnumMovie.create!(name: "Airplane!", genre: :comedy, tenant_id: @tenant.id)

    by_label = Bali::FilterForm.new(StringEnumMovie.all, params({ g: { "0" => { genre_eq: "action" } } }))
    by_value = Bali::FilterForm.new(StringEnumMovie.all, params({ g: { "0" => { genre_eq: "Action" } } }))

    assert_equal "Action", by_label.ransack_params[:g]["0"]["genre_eq"]
    assert_equal "Action", by_value.ransack_params[:g]["0"]["genre_eq"]
    # Assert the set and not the equality between the two: both paths break TOGETHER, so comparing
    # one against the other passes just as well with both empty.
    assert_equal [ action.name ], by_label.result.pluck(:name)
    assert_equal [ action.name ], by_value.result.pluck(:name)
  end

  def test_compound_predicates_translate_every_member
    filter_params = { g: { "0" => { status_eq_any: %w[done draft] } } }
    form = EnumMovieFilterForm.new(@tenant.movies, params(filter_params))

    assert_equal [ 1, 0 ], form.ransack_params[:g]["0"]["status_eq_any"]
  end

  # The repo's tests use doubles as scope. With no `defined_enums` there is nothing to translate
  # and the module is a no-op: it cannot blow up. #result is not called — that would be
  # `[].ransack`.
  def test_a_scope_without_a_model_does_not_raise
    form = Bali::FilterForm.new([], params({ g: { "0" => { status_eq: "done" } } }))

    assert_equal "done", form.ransack_params[:g]["0"]["status_eq"]
  end

  # Anti-drift: the predicates we translate are EXACTLY the ones the select UI offers. Add an
  # operator to the select and this fails, forcing the decision.
  def test_the_translated_predicates_are_the_ones_the_select_ui_offers
    assert_equal Bali::Filters::Operators.for_type(:select).pluck(:value).sort,
                 Bali::FilterForm::EnumCasting::EQUALITY_PREDICATES.sort
  end
end

# --- Period presets (#725): a symbolic token in the SAME param as the range ---
class DateRangePresetsFilterFormTest < ActiveSupport::TestCase
  class PresetsFilterForm < Bali::FilterForm
    filter_attribute :created_at, type: :date, input: :date_range, simple: true,
                     advanced: false, label: "Created",
                     presets: %i[today this_week this_month]
  end

  class AllPresetsFilterForm < Bali::FilterForm
    filter_attribute :created_at, type: :date, input: :date_range, simple: true,
                     advanced: false, presets: true
  end

  def setup
    @tenant = Tenant.create(name: "Tenant")
    travel_to Time.zone.parse("2026-08-06 12:00:00") do
      @today = @tenant.movies.create(name: "Today", status: 0)
      @this_week = @tenant.movies.create(name: "Monday", status: 0, created_at: 3.days.ago)
      @this_month = @tenant.movies.create(name: "First", status: 0, created_at: Time.zone.parse("2026-08-01 09:00"))
      @last_month = @tenant.movies.create(name: "July", status: 0, created_at: Time.zone.parse("2026-07-15 09:00"))
    end
  end

  def params(filter_attributes)
    ActionController::Parameters.new(q: filter_attributes)
  end

  # The heart of decision 725-D1: the token resolves against Time.zone AT QUERY TIME, not at
  # declaration, so the same stored value narrows differently on another date.
  def test_a_token_narrows_the_result_to_the_period_it_names
    travel_to Time.zone.parse("2026-08-06 18:00:00") do
      form = PresetsFilterForm.new(@tenant.movies, params(created_at: "today"))
      assert_equal [ "Today" ], form.result.pluck(:name)
    end
  end

  def test_this_week_and_this_month_widen_the_same_way_the_calendar_does
    travel_to Time.zone.parse("2026-08-06 18:00:00") do
      week = PresetsFilterForm.new(@tenant.movies, params(created_at: "this_week"))
      assert_equal %w[Monday Today], week.result.pluck(:name).sort

      month = PresetsFilterForm.new(@tenant.movies, params(created_at: "this_month"))
      assert_equal %w[First Monday Today], month.result.pluck(:name).sort
    end
  end

  # What a literal range in a saved view does NOT do: go on meaning the same thing.
  def test_the_same_token_means_the_new_month_a_month_later
    august = travel_to(Time.zone.parse("2026-08-06 18:00:00")) do
      PresetsFilterForm.new(@tenant.movies, params(created_at: "this_month")).result.count
    end
    september = travel_to(Time.zone.parse("2026-09-06 18:00:00")) do
      PresetsFilterForm.new(@tenant.movies, params(created_at: "this_month")).result.count
    end

    assert_equal 3, august
    assert_equal 0, september
  end

  # A preset does not replace the explicit range: they travel in the SAME param and both filter.
  def test_an_explicit_range_still_travels_in_the_same_param
    form = PresetsFilterForm.new(@tenant.movies, params(created_at: "2026-07-01 to 2026-07-31"))

    assert_equal [ "July" ], form.result.pluck(:name)
  end

  def test_a_token_counts_as_an_active_filter
    form = PresetsFilterForm.new(@tenant.movies, params(created_at: "this_month"))

    assert form.active_filters?
    assert_equal({ "created_at" => "this_month" }, form.active_filters)
  end

  # DSL

  def test_presets_reach_the_simple_filters_config_in_the_declared_order
    config = PresetsFilterForm.new(@tenant.movies, params({}))
                              .simple_filters_config.find { |c| c[:attribute] == :created_at }

    assert_equal %w[today this_week this_month], config[:presets]
  end

  def test_presets_true_offers_every_token
    config = AllPresetsFilterForm.new(@tenant.movies, params({}))
                                 .simple_filters_config.find { |c| c[:attribute] == :created_at }

    assert_equal Bali::DateRangePresets::TOKENS, config[:presets]
  end

  def test_a_filter_without_presets_carries_none
    config = Bali::FilterForm.new(
      @tenant.movies, params({}),
      simple_filters: [ { attribute: :created_at, type: :date_range, label: "Created" } ]
    ).simple_filters_config.first

    assert_nil config[:presets]
  end

  def test_instance_level_simple_filters_take_presets_too
    config = Bali::FilterForm.new(
      @tenant.movies, params({}),
      simple_filters: [ { attribute: :created_at, type: :date_range, presets: true } ]
    ).simple_filters_config.first

    assert_equal Bali::DateRangePresets::TOKENS, config[:presets]
  end

  def test_an_unknown_preset_raises_at_declaration_time
    error = assert_raises(ArgumentError) do
      Class.new(Bali::FilterForm) do
        filter_attribute :created_at, type: :date, input: :date_range, simple: true,
                         presets: %i[this_millennium]
      end
    end
    assert_match(/unknown date range preset/, error.message)
  end

  # 725-D4: "this week" is not a value a single date can hold.
  def test_presets_on_a_single_date_filter_raise
    error = assert_raises(ArgumentError) do
      Class.new(Bali::FilterForm) do
        filter_attribute :release_date, type: :date, simple: true, presets: %i[today]
      end
    end
    assert_match(/needs input: :date_range/, error.message)
  end

  def test_an_unknown_preset_from_an_instance_level_hash_raises_too
    form = Bali::FilterForm.new(
      @tenant.movies, params({}),
      simple_filters: [ { attribute: :created_at, type: :date_range, presets: %i[whenever] } ]
    )

    assert_raises(ArgumentError) { form.simple_filters_config }
  end

  # A round trip through the RENDERED form: the token has to survive the journey through the hidden
  # field the widget emits, not only through a hash written by hand in the test.
  def test_the_token_survives_the_round_trip_through_the_rendered_form
    config = PresetsFilterForm.new(@tenant.movies, params(created_at: "this_month"))
                              .simple_filters_config

    html = ApplicationController.render(
      Bali::DataTable::SimpleFilters::Component.new(url: "/movies", filters: config),
      layout: false
    )
    hidden = Capybara.string(html).find("input[type=hidden][name='q[created_at]']", visible: :all)

    resubmitted = PresetsFilterForm.new(@tenant.movies, params(created_at: hidden[:value]))
    travel_to(Time.zone.parse("2026-08-06 18:00:00")) do
      assert_equal 3, resubmitted.result.count
    end
  end
end
