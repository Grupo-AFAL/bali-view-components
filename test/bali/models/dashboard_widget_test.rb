# frozen_string_literal: true

require "test_helper"

class BaliDashboardWidgetTest < ActiveSupport::TestCase
  # No fixtures in this repo; the house pattern is an inline create.
  # See test/bali/models/saved_view_test.rb.
  def owner
    @owner ||= User.create!(name: "Ana")
  end

  def build(**overrides)
    Bali::DashboardWidget.new({
      owner: owner, context: "1", dashboard_key: "today",
      widget_key: "low_stock_items", position: 0
    }.merge(overrides))
  end

  def test_is_valid_with_the_full_scope
    assert_predicate build, :valid?
  end

  def test_requires_a_dashboard_key_a_widget_key_and_a_position
    refute_predicate build(dashboard_key: nil), :valid?
    refute_predicate build(widget_key: nil), :valid?
    refute_predicate build(position: nil), :valid?
  end

  def test_rejects_a_negative_position
    refute_predicate build(position: -1), :valid?
  end

  def test_a_widget_key_is_unique_within_one_dashboard
    build.save!

    refute_predicate build, :valid?
  end

  def test_the_same_widget_key_is_free_in_another_context_or_dashboard
    build.save!

    assert_predicate build(context: "2"), :valid?
    assert_predicate build(dashboard_key: "finance"), :valid?
  end

  def test_ordered_breaks_ties_on_widget_key
    # Two rows CAN share a position: a row for a widget the owner cannot see
    # keeps its position while the visible ones renumber around it. Without the
    # tie-break Postgres returns those in arbitrary order, which makes
    # Layout#stored_keys nondeterministic.
    build(widget_key: "zulu", position: 0).save!
    build(widget_key: "alpha", position: 0).save!

    assert_equal %w[alpha zulu], Bali::DashboardWidget.ordered.pluck(:widget_key)
  end

  def test_context_defaults_to_the_empty_string_for_a_single_tenant_host
    row = Bali::DashboardWidget.create!(owner: owner, dashboard_key: "today",
                                        widget_key: "solo", position: 0)

    assert_equal "", row.reload.context
  end
end
