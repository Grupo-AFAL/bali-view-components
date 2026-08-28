# frozen_string_literal: true

require "test_helper"

class BaliDashboardWidgetStoreTest < ActiveSupport::TestCase
  def self.widget(key, size)
    # `ValueBase`, not `Base` directly: a widget IS one of the four patterns.
    # The store only ever reads keys and sizes, so the figure is a constant.
    Class.new(Bali::Widget::ValueBase) do
      supports(*Bali::Widget::SIZES)
      default_size size
      define_singleton_method(:key) { key }
      define_singleton_method(:title) { key }
      value { 0 }
    end
  end

  ALPHA = widget("alpha", :small)
  BRAVO = widget("bravo", :medium)
  CHARLIE = widget("charlie", :large)

  # No fixtures in this repo; the house pattern is an inline create.
  # See test/bali/models/saved_view_test.rb.
  def owner
    @owner ||= User.create!(name: "Ana")
  end

  def offering = [ ALPHA.new, BRAVO.new, CHARLIE.new ]

  def store(offer: offering)
    Bali::DashboardWidget::Store.new(owner: owner, context: "1",
                                     dashboard_key: "today", offering: offer)
  end

  def keys_of(widgets) = widgets.map(&:key)

  def rows_by_key
    Bali::DashboardWidget.where(owner: owner, context: "1", dashboard_key: "today")
                         .index_by(&:widget_key)
  end

  # THE OFFERING IS THE FEATURE'S SECURITY PROPERTY — a submitted key becomes a
  # widget only by being found in it — and until the Store gated it, that
  # property rested on every host remembering one `authorized_for` call. A host
  # passing its raw catalogue persisted and rendered widgets whose `authorized?`
  # was false, silently.
  def test_the_store_gates_the_offering_it_is_handed
    hidden = Class.new(Bali::Widget::ValueBase) do
      def self.key = "payroll"
      value { 999 }
      def authorized? = false
    end.new

    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ ALPHA.new, hidden ])
    store.arrange([ Bali::Widget::Placement.new(widget: hidden, size: :small), Bali::Widget::Placement.new(widget: ALPHA.new, size: :small) ])

    assert_equal [ "alpha" ], store.stored_keys
    assert_equal [ "alpha" ], store.widgets.map(&:key)
  end

  # `Layout` gates independently, so neither boundary relies on the other.
  def test_layout_drops_a_key_the_owner_cannot_see
    hidden = Class.new(Bali::Widget::ValueBase) do
      def self.key = "payroll"
      value { 999 }
      def authorized? = false
    end.new
    params = { widgets: [ { key: "payroll", size: "small" } ] }.with_indifferent_access

    assert_empty Bali::Widget::Layout.from(params, offering: [ hidden ])
    assert_empty Bali::Widget::Layout.chosen({ widget_keys: [ "payroll" ] }.with_indifferent_access,
                                             offering: [ hidden ])
  end

  # Bali does NOT memoise for a host: the default is a constant, and a host whose
  # rule is expensive knows that where Bali cannot. What matters is that the
  # gating boundaries are few and named, not that they are one.
  def test_each_gating_boundary_asks_once
    calls = 0
    widget = ALPHA.new
    widget.define_singleton_method(:authorized?) { calls += 1; true }

    Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ widget ])

    assert_equal 1, calls
  end

  def test_offering_is_required
    assert_raises(ArgumentError) do
      Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "today")
    end
  end

  def test_with_no_rows_it_returns_the_whole_offering_in_catalog_order
    assert_equal %w[alpha bravo charlie], keys_of(store.widgets)
    refute_predicate store, :customized?
  end

  def test_arrange_stores_order_and_size
    store.arrange([ Bali::Widget::Placement.new(widget: CHARLIE.new, size: "large"), Bali::Widget::Placement.new(widget: ALPHA.new) ])

    stored = store.widgets

    assert_equal %w[charlie alpha], keys_of(stored)
    assert_equal :large, stored.first.size
    # No size submitted means "no opinion": the widget renders at its own.
    assert_equal :small, stored.last.size
    assert_predicate store, :customized?
  end

  # `arrange` is `delete_all` + `insert_all`, so without carrying them forward a
  # widget that has sat on the dashboard for a year would get a fresh
  # `created_at` every time anything is dragged — and "when did you first add
  # this widget?" would be permanently unanswerable from this table.
  def test_a_rearrange_preserves_when_a_widget_was_first_added
    travel_to Time.zone.local(2026, 1, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new), Bali::Widget::Placement.new(widget: BRAVO.new) ])
    end

    travel_to Time.zone.local(2026, 6, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: BRAVO.new), Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    born = rows_by_key.transform_values(&:created_at)

    assert_equal Time.zone.local(2026, 1, 1), born["alpha"]
    assert_equal Time.zone.local(2026, 1, 1), born["bravo"]
  end

  # The other half: a widget that was NOT there is genuinely new, and dating it
  # to the arrangement it first appeared in is the whole point of keeping these.
  def test_a_newly_added_widget_is_dated_now_not_backfilled
    travel_to Time.zone.local(2026, 1, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    travel_to Time.zone.local(2026, 6, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new), Bali::Widget::Placement.new(widget: CHARLIE.new) ])
    end

    born = rows_by_key.transform_values(&:created_at)

    assert_equal Time.zone.local(2026, 1, 1), born["alpha"]
    assert_equal Time.zone.local(2026, 6, 1), born["charlie"]
  end

  # `updated_at` is the opposite promise: the row really was just rewritten.
  def test_a_rearrange_still_stamps_updated_at
    travel_to Time.zone.local(2026, 1, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    travel_to Time.zone.local(2026, 6, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    assert_equal Time.zone.local(2026, 6, 1), rows_by_key["alpha"].updated_at
  end

  # Removing a widget and adding it back is "off" then "on", not a restoration:
  # `reset` and an emptied grid both drop the rows outright, so there is nothing
  # left to carry a birthday forward from.
  def test_a_widget_removed_and_re_added_is_dated_from_its_return
    travel_to Time.zone.local(2026, 1, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    travel_to Time.zone.local(2026, 3, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: BRAVO.new) ])
    end

    travel_to Time.zone.local(2026, 6, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: BRAVO.new), Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    assert_equal Time.zone.local(2026, 6, 1), rows_by_key["alpha"].created_at
    assert_equal Time.zone.local(2026, 3, 1), rows_by_key["bravo"].created_at
  end

  def test_arrange_is_a_full_reconcile_not_an_append
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new), Bali::Widget::Placement.new(widget: BRAVO.new) ])
    store.arrange([ Bali::Widget::Placement.new(widget: BRAVO.new) ])

    assert_equal %w[bravo], keys_of(store.widgets)
  end

  def test_a_retired_size_falls_back_to_the_widget_s_own
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new, size: "enormous") ])

    assert_equal :small, store.widgets.first.size
  end

  def test_a_stored_key_outside_the_offering_renders_nothing_and_is_not_visible
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new), Bali::Widget::Placement.new(widget: CHARLIE.new) ])

    narrowed = store(offer: [ ALPHA.new ])

    assert_equal %w[alpha], keys_of(narrowed.widgets)
    assert_equal %w[alpha charlie], narrowed.stored_keys
    assert_equal %w[alpha], narrowed.visible_keys
  end

  def test_a_dashboard_of_only_invisible_rows_falls_back_to_the_offering
    store.arrange([ Bali::Widget::Placement.new(widget: CHARLIE.new) ])

    narrowed = store(offer: [ ALPHA.new, BRAVO.new ])

    # No VISIBLE rows means "never chose", so this is defaults, not an empty page
    # — and `customized?` must agree, or the host offers "restore defaults" to
    # someone already looking at them.
    assert_equal %w[alpha bravo], keys_of(narrowed.widgets)
    refute_predicate narrowed, :customized?
  end

  def test_choose_keeps_stored_order_for_survivors_and_appends_the_rest
    store.arrange([ Bali::Widget::Placement.new(widget: CHARLIE.new), Bali::Widget::Placement.new(widget: ALPHA.new) ])
    store.choose([ ALPHA.new, BRAVO.new, CHARLIE.new ])

    assert_equal %w[charlie alpha bravo], keys_of(store.widgets)
  end

  def test_choose_does_not_resize
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new, size: "large") ])
    store.choose([ ALPHA.new, BRAVO.new ])

    assert_equal :large, store.widgets.first.size
  end

  def test_choose_dedupes_so_a_repeated_key_cannot_collide_on_the_unique_index
    store.choose([ ALPHA.new, ALPHA.new ])

    assert_equal %w[alpha], store.stored_keys
  end

  def test_reset_drops_every_row
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    store.reset

    assert_empty store.stored_keys
    assert_equal %w[alpha bravo charlie], keys_of(store.widgets)
  end

  def test_an_empty_arrange_is_a_reset
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    store.arrange([])

    assert_empty store.stored_keys
  end

  # `choose`'s own union already dedupes before it calls `arrange`, but
  # `arrange` is a lower-level primitive a host's controller can call
  # directly from params — where nothing guarantees a unique key. Without an
  # explicit dedupe, `insert_all`'s `ON CONFLICT DO NOTHING` silently keeps
  # only the first occurrence and drops the rest with no error.
  def test_arrange_dedupes_a_repeated_key_instead_of_silently_dropping_it
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new, size: "large"), Bali::Widget::Placement.new(widget: ALPHA.new, size: "large") ])

    assert_equal %w[alpha], store.stored_keys
  end

  def test_rows_are_scoped_to_the_context_and_dashboard
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])

    other_context = Bali::DashboardWidget::Store.new(owner: owner, context: "2",
                                                      dashboard_key: "today", offering: offering)
    other_dashboard = Bali::DashboardWidget::Store.new(owner: owner, context: "1",
                                                        dashboard_key: "finance", offering: offering)

    assert_empty other_context.stored_keys
    assert_empty other_dashboard.stored_keys
  end
end
