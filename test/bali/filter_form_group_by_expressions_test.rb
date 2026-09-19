# frozen_string_literal: true

require "test_helper"

# #1102. `group_by_attribute` only accepted real columns: a `ransacker` or an association path
# —the two things Ransack sorts by without blinking— reached the SQL as bare identifiers and blew
# up there. These tests pin both halves of the fix: that the GROUP BY comes out of the SAME Arel as
# the ORDER BY, and that a declaration that cannot work fails when the form is built and not when
# somebody picks that grouping on screen.
class BaliFilterFormGroupByExpressionsTest < ActiveSupport::TestCase
  # A ransacker (SQL expression), an association path and a plain old column, on the same form: the
  # three shapes coexist.
  class MixedGroupingsFilterForm < Bali::FilterForm
    group_by_attribute :genre
    group_by_attribute :budget_band, label: "Presupuesto"
    group_by_attribute :studio_name, label: "Estudio", value: ->(movie) { movie.studio&.name }

    attribute :genre_eq
  end

  def setup
    @acme = Tenant.create!(name: "Acme")
    @orbit = Tenant.create!(name: "Orbit")

    @big = Movie.create!(name: "Big", genre: "Action", budget: 90_000_000, studio: @acme)
    @mid = Movie.create!(name: "Mid", genre: "Action", budget: 6_000_000, studio: @acme)
    @small = Movie.create!(name: "Small", genre: "Drama", budget: 100_000, studio: @orbit)
    @broke = Movie.create!(name: "Broke", genre: "Drama", budget: nil, studio: @orbit)
  end

  def group_params(group_by, q: {})
    ActionController::Parameters.new(q: ActionController::Parameters.new(q), group_by: group_by)
  end

  def form(group_by, **options)
    MixedGroupingsFilterForm.new(Movie.all, group_params(group_by, **options))
  end

  # --- Ransacker ---

  # The head of the issue: `group(:budget_band)` was a `PG::UndefinedColumn` because the symbol
  # arrived raw. Now the GROUP BY runs over the ransacker's CASE.
  def test_a_ransacker_groups_instead_of_raising
    assert_equal({ "blockbuster" => 1, "mid" => 1, "indie" => 2 },
                 form("budget_band").group_counts)
  end

  def test_a_ransacker_group_by_runs_on_the_ransackers_own_arel
    sql = form("budget_band").group_by_expression.to_sql

    assert_includes sql, "CASE"
    assert_includes sql, "budget"
  end

  # The ransacker's ORDER BY already worked and is still built through Ransack's `s` param: the rows
  # gather into bands before the table paints them.
  def test_a_ransacker_still_orders_through_ransack
    assert_equal([ "budget_band asc" ], form("budget_band").ransack_params["s"])
  end

  # A row's band comes out of the Ruby twin, and has to match the key the GROUP BY returned or the
  # header loses the global count.
  def test_a_ransacker_row_reads_its_band_through_the_ruby_twin
    grouped = form("budget_band")

    assert_equal("blockbuster", grouped.group_value_for(@big))
    assert_equal("indie", grouped.group_value_for(@broke))
    assert_includes grouped.group_counts.keys, grouped.group_value_for(@big)
  end

  # --- Association path ---

  def test_an_association_path_groups_over_the_joined_column
    assert_equal({ "Acme" => 2, "Orbit" => 2 }, form("studio_name").group_counts)
  end

  # The grouping does not add the join: it is already there because the grouping is prepended as a
  # sort and Ransack builds it when the relation is evaluated. One join too many is a cartesian product.
  def test_an_association_path_reuses_the_join_ransack_already_built
    sql = form("studio_name").result.to_sql

    assert_equal 1, sql.scan(/JOIN "tenants"/).size
  end

  # There is no `movie.studio_name` for an association path: hence `value:`.
  def test_an_association_path_reads_its_band_through_the_declared_value
    assert_equal("Acme", form("studio_name").group_value_for(@big))
  end

  # --- A plain column (what already worked) ---

  def test_a_plain_column_keeps_grouping_as_before
    grouped = form("genre")

    assert_equal({ "Action" => 2, "Drama" => 2 }, grouped.group_counts)
    assert_equal("Action", grouped.group_value_for(@big))
  end

  # An enum's keys are still the labels and not the integers: the Arel now feeding the GROUP BY
  # keeps the column type's cast.
  def test_an_enum_column_still_returns_label_keys
    enum_form = Class.new(Bali::FilterForm) { group_by_attribute :status }
    @big.update!(status: :done)

    assert_equal({ "draft" => 3, "done" => 1 },
                 enum_form.new(Movie.all, group_params("status")).group_counts)
  end

  # --- Filters and suspension still rule ---

  def test_group_counts_of_an_expression_respect_active_filters
    filtered = form("budget_band", q: { genre_eq: "Action" })

    assert_equal({ "blockbuster" => 1, "mid" => 1 }, filtered.group_counts)
  end

  def test_group_value_is_nil_when_no_grouping_is_applied
    assert_nil form(nil).group_value_for(@big)
  end

  # --- Explicit `sql:` ---

  # The escape hatch: an expression neither a column nor a ransacker can say. It rules BOTH halves,
  # because grouping by one expression and ordering by another gathers nothing.
  BUDGETED_SQL = "CASE WHEN movies.budget IS NULL THEN 'sin presupuesto' " \
                 "ELSE 'con presupuesto' END"

  class ExplicitSqlFilterForm < Bali::FilterForm
    group_by_attribute :budgeted,
                       label: "Presupuesto",
                       sql: -> { BUDGETED_SQL },
                       value: ->(movie) { movie.budget.present? ? "con presupuesto" : "sin presupuesto" }
  end

  def explicit_form
    ExplicitSqlFilterForm.new(Movie.all, group_params("budgeted"))
  end

  # The keys are still the ones the GROUP BY returned —raw— so the expression and the `value:` have
  # to speak the same language or the header loses the global count.
  def test_an_explicit_sql_expression_drives_the_group_by
    grouped = explicit_form

    assert_equal({ "con presupuesto" => 3, "sin presupuesto" => 1 }, grouped.group_counts)
    assert_equal("sin presupuesto", grouped.group_value_for(@broke))
    assert_includes grouped.group_counts.keys, grouped.group_value_for(@broke)
  end

  # It does not go through Ransack's `s` param —which only speaks of names— but through a reorder
  # over the already-evaluated relation.
  def test_an_explicit_sql_expression_orders_the_relation_itself
    assert_nil explicit_form.ransack_params["s"]
    assert_includes explicit_form.result.to_sql, "ORDER BY #{BUDGETED_SQL} ASC"
  end

  # The user's sort survives behind the grouping (sort-within-groups), just as in the half that does
  # go through Ransack.
  def test_an_explicit_sql_expression_keeps_the_user_sort_behind_it
    sorted = ExplicitSqlFilterForm.new(
      Movie.all,
      ActionController::Parameters.new(q: { s: "name desc" }, group_by: "budgeted")
    )

    assert_includes sorted.result.to_sql, %(ORDER BY #{BUDGETED_SQL} ASC, "movies"."name" DESC)
  end

  # --- Fail at declaration, not at query time ---

  def test_an_attribute_that_is_neither_column_ransacker_nor_path_raises_on_build
    bogus = Class.new(Bali::FilterForm) { group_by_attribute :lo_que_sea }

    error = assert_raises(ArgumentError) { bogus.new(Movie.all, group_params(nil)) }
    assert_match(/group_by_attribute :lo_que_sea/, error.message)
    assert_match(/no column, ransacker or reachable association path/, error.message)
  end

  # It blows up WHETHER OR NOT the param arrives: were it to wait for somebody to pick that grouping,
  # it would still be a production error on a screen that had loaded fine a thousand times.
  def test_the_declaration_raises_even_when_no_group_by_param_arrives
    bogus = Class.new(Bali::FilterForm) { group_by_attribute :lo_que_sea }

    assert_raises(ArgumentError) { bogus.new(Movie.all, ActionController::Parameters.new) }
  end

  # The GROUP BY resolves but the row cannot be read: `movie.studio_name` is a NoMethodError.
  def test_an_association_path_without_a_value_reader_raises_on_build
    reader_less = Class.new(Bali::FilterForm) { group_by_attribute :studio_name }

    error = assert_raises(ArgumentError) { reader_less.new(Movie.all, group_params(nil)) }
    assert_match(/Pass `value:`/, error.message)
  end

  def test_an_explicit_sql_declaration_needs_no_ransack_name
    assert_nothing_raised { explicit_form }
  end

  # With no model there is nothing to verify, and a validation that blows up over a scope that is not
  # a relation would be worse than the one that did not exist.
  def test_a_scope_without_a_model_skips_validation
    assert_nothing_raised do
      Class.new(Bali::FilterForm) { group_by_attribute :lo_que_sea }.new([], group_params(nil))
    end
  end
end
