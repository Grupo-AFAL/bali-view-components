# frozen_string_literal: true

require "test_helper"

# #1096. `default:` used to reach the SimpleFilters widget and stop there — the select read
# "Active" over a listing that showed everything. These pin the `q` params that make the
# control, the query and the link say one thing; `Bali::Filterable#redirect_to_default_filters`
# is what puts them in the URL.
class BaliFilterFormDefaultFiltersTest < ActiveSupport::TestCase
  def test_a_form_with_no_defaults_has_no_default_params
    form = Class.new(Bali::FilterForm) do
      filter_attribute :genre, type: :select, simple: true, options: [ %w[Drama drama] ]
    end

    assert_empty form.default_filter_params
  end

  # A `simple: true` attribute travels flat under `q`, which is where its own control
  # reads it back from: the default lands IN the select rather than beside it.
  def test_a_simple_default_travels_flat_under_q
    form = Class.new(Bali::FilterForm) do
      filter_attribute :status, type: :select, simple: true, default: "active",
                                options: [ %w[Active active] ]
    end

    assert_equal({ "status_eq" => "active" }, form.default_filter_params)
  end

  def test_a_simple_default_uses_the_declared_predicate
    form = Class.new(Bali::FilterForm) do
      filter_attribute :name, type: :text, input: :select, simple: true,
                              predicate: :cont, default: "godfather"
    end

    assert_equal({ "name_cont" => "godfather" }, form.default_filter_params)
  end

  # An attribute that only lives in the advanced popover has no control of its own to sit
  # in, so it becomes a condition of the panel's first group — a pill the user can remove.
  def test_an_advanced_default_becomes_a_condition_of_the_first_group
    form = Class.new(Bali::FilterForm) do
      filter_attribute :status, type: :select, default: "active", options: [ %w[Active active] ]
    end

    assert_equal({ "g" => { "0" => { "status_eq" => "active", "m" => "and" } } },
                 form.default_filter_params)
  end

  # `m` goes in explicitly because a group with no combinator parses as OR, and two
  # defaults are the one question a listing opens with — both of them, not either.
  def test_two_advanced_defaults_share_the_group_and_are_ANDed
    form = Class.new(Bali::FilterForm) do
      filter_attribute :status, type: :select, default: "active"
      filter_attribute :country, type: :select, default: "MX"
    end

    assert_equal({ "g" => { "0" => { "status_eq" => "active", "country_eq" => "MX",
                                     "m" => "and" } } },
                 form.default_filter_params)
  end

  def test_the_two_shapes_coexist_in_one_form
    form = Class.new(Bali::FilterForm) do
      filter_attribute :status, type: :select, simple: true, default: "active"
      filter_attribute :country, type: :select, default: "MX"
    end

    assert_equal({ "status_eq" => "active",
                   "g" => { "0" => { "country_eq" => "MX", "m" => "and" } } },
                 form.default_filter_params)
  end

  # `present?` would eat this one: a listing that opens showing only the negatives is a
  # real listing, and `false` is a value Ransack applies.
  def test_a_false_default_is_a_default
    form = Class.new(Bali::FilterForm) do
      filter_attribute :archived, type: :boolean, simple: true, default: false
    end

    assert_equal({ "archived_eq" => false }, form.default_filter_params)
  end

  def test_a_blank_default_is_not_a_default
    form = Class.new(Bali::FilterForm) do
      filter_attribute :status, type: :select, simple: true, default: ""
      filter_attribute :country, type: :select, simple: true, default: nil
    end

    assert_empty form.default_filter_params
  end

  # A default has to be visible and removable somewhere, or it filters invisibly — which
  # is the whole failure this feature exists to end. Caught at class-definition time.
  def test_a_default_on_an_attribute_offered_in_no_ui_is_rejected
    error = assert_raises(ArgumentError) do
      Class.new(Bali::FilterForm) do
        filter_attribute :status, type: :select, simple: false, advanced: false,
                                  default: "active"
      end
    end

    assert_match(/default: needs a UI to live in/, error.message)
  end

  def test_an_attribute_offered_in_no_ui_is_fine_without_a_default
    form = Class.new(Bali::FilterForm) do
      filter_attribute :status, type: :select, simple: false, advanced: false
    end

    assert_empty form.default_filter_params
  end

  # A date range has no single Ransack predicate — it is applied with a `where` clause —
  # so it travels under the bare attribute name, the same key its widget submits.
  def test_a_date_range_default_travels_under_the_bare_attribute
    form = Class.new(Bali::FilterForm) do
      filter_attribute :created_at, type: :date, input: :date_range, simple: true,
                                    default: "this_month"
    end

    assert_equal({ "created_at" => "this_month" }, form.default_filter_params)
  end

  # And a number range is a pair, which is how its widget reads its own value back.
  def test_a_number_range_default_becomes_a_gteq_lteq_pair
    form = Class.new(Bali::FilterForm) do
      filter_attribute :year, type: :number, simple: true, default: { min: 1990, max: 2000 }
    end

    assert_equal({ "year_gteq" => 1990, "year_lteq" => 2000 }, form.default_filter_params)
  end

  def test_a_half_open_number_range_default_only_carries_the_half_it_has
    form = Class.new(Bali::FilterForm) do
      filter_attribute :year, type: :number, simple: true, default: { min: 1990 }
    end

    assert_equal({ "year_gteq" => 1990 }, form.default_filter_params)
  end

  def test_a_callable_default_is_resolved
    form = Class.new(Bali::FilterForm) do
      filter_attribute :status, type: :select, simple: true, default: -> { "active" }
    end

    assert_equal({ "status_eq" => "active" }, form.default_filter_params)
  end

  def test_defaults_are_inherited_with_the_attributes
    parent = Class.new(Bali::FilterForm) do
      filter_attribute :status, type: :select, simple: true, default: "active"
    end

    assert_equal({ "status_eq" => "active" }, Class.new(parent).default_filter_params)
  end

  # The whole point of putting them in the URL: they parse back as the state the panel
  # renders and Ransack applies, rather than as something injected underneath.
  def test_the_emitted_params_parse_back_into_applied_filter_state
    form_class = Class.new(Bali::FilterForm) do
      filter_attribute :genre, type: :select, default: "Drama"
    end
    params = ActionController::Parameters.new(q: form_class.default_filter_params)

    form = form_class.new(Movie.all, params)

    assert_equal [ { attribute: "genre", operator: "eq", value: "Drama" } ],
                 form.applied_filter_conditions
    assert_equal({ g: { "0" => { "genre_eq" => "Drama", "m" => "and" } } },
                 form.ransack_params.slice(:g))
  end

  def test_a_simple_default_parses_back_as_that_filter_s_current_value
    form_class = Class.new(Bali::FilterForm) do
      filter_attribute :genre, type: :select, simple: true, default: "Drama",
                               options: [ %w[Drama Drama] ]
    end
    params = ActionController::Parameters.new(q: form_class.default_filter_params)

    form = form_class.new(Movie.all, params)

    assert_equal({ "genre_eq" => "Drama" }, form.active_simple_filters)
  end
end
