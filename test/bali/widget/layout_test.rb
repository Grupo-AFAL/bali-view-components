# frozen_string_literal: true

require "test_helper"

class BaliWidgetLayoutTest < ActiveSupport::TestCase
  def self.widget(key, size)
    Class.new(Bali::Widget::Base) do
      sized size
      define_singleton_method(:key) { key }
      define_singleton_method(:title) { key }
      def call = Bali::Widget::Result.new
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

  def layout(offer: offering)
    Bali::Widget::Layout.new(owner: owner, context: "1",
                             dashboard_key: "today", offering: offer)
  end

  def keys_of(widgets) = widgets.map(&:key)

  def test_offering_is_required
    assert_raises(ArgumentError) do
      Bali::Widget::Layout.new(owner: owner, dashboard_key: "today")
    end
  end

  def test_with_no_rows_it_returns_the_whole_offering_in_catalog_order
    assert_equal %w[alpha bravo charlie], keys_of(layout.widgets)
    refute_predicate layout, :customized?
  end

  def test_arrange_stores_order_and_size
    layout.arrange([ { widget: CHARLIE.new, size: "wide" }, { widget: ALPHA.new } ])

    stored = layout.widgets

    assert_equal %w[charlie alpha], keys_of(stored)
    assert_equal :wide, stored.first.size
    # No size submitted means "no opinion": the widget renders at its own.
    assert_equal :small, stored.last.size
    assert_predicate layout, :customized?
  end

  def test_arrange_is_a_full_reconcile_not_an_append
    layout.arrange([ { widget: ALPHA.new }, { widget: BRAVO.new } ])
    layout.arrange([ { widget: BRAVO.new } ])

    assert_equal %w[bravo], keys_of(layout.widgets)
  end

  def test_a_retired_size_falls_back_to_the_widget_s_own
    layout.arrange([ { widget: ALPHA.new, size: "enormous" } ])

    assert_equal :small, layout.widgets.first.size
  end

  def test_a_stored_key_outside_the_offering_renders_nothing_and_is_not_visible
    layout.arrange([ { widget: ALPHA.new }, { widget: CHARLIE.new } ])

    narrowed = layout(offer: [ ALPHA.new ])

    assert_equal %w[alpha], keys_of(narrowed.widgets)
    assert_equal %w[alpha charlie], narrowed.stored_keys
    assert_equal %w[alpha], narrowed.visible_keys
  end

  def test_a_dashboard_of_only_invisible_rows_falls_back_to_the_offering
    layout.arrange([ { widget: CHARLIE.new } ])

    narrowed = layout(offer: [ ALPHA.new, BRAVO.new ])

    # No VISIBLE rows means "never chose", so this is defaults, not an empty page
    # — and `customized?` must agree, or the host offers "restore defaults" to
    # someone already looking at them.
    assert_equal %w[alpha bravo], keys_of(narrowed.widgets)
    refute_predicate narrowed, :customized?
  end

  def test_choose_keeps_stored_order_for_survivors_and_appends_the_rest
    layout.arrange([ { widget: CHARLIE.new }, { widget: ALPHA.new } ])
    layout.choose([ ALPHA.new, BRAVO.new, CHARLIE.new ])

    assert_equal %w[charlie alpha bravo], keys_of(layout.widgets)
  end

  def test_choose_does_not_resize
    layout.arrange([ { widget: ALPHA.new, size: "wide" } ])
    layout.choose([ ALPHA.new, BRAVO.new ])

    assert_equal :wide, layout.widgets.first.size
  end

  def test_choose_dedupes_so_a_repeated_key_cannot_collide_on_the_unique_index
    layout.choose([ ALPHA.new, ALPHA.new ])

    assert_equal %w[alpha], layout.stored_keys
  end

  def test_reset_drops_every_row
    layout.arrange([ { widget: ALPHA.new } ])
    layout.reset

    assert_empty layout.stored_keys
    assert_equal %w[alpha bravo charlie], keys_of(layout.widgets)
  end

  def test_an_empty_arrange_is_a_reset
    layout.arrange([ { widget: ALPHA.new } ])
    layout.arrange([])

    assert_empty layout.stored_keys
  end

  def test_rows_are_scoped_to_the_context_and_dashboard
    layout.arrange([ { widget: ALPHA.new } ])

    other_context = Bali::Widget::Layout.new(owner: owner, context: "2",
                                             dashboard_key: "today", offering: offering)
    other_dashboard = Bali::Widget::Layout.new(owner: owner, context: "1",
                                               dashboard_key: "finance", offering: offering)

    assert_empty other_context.stored_keys
    assert_empty other_dashboard.stored_keys
  end
end
