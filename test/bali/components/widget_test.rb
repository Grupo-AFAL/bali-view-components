# frozen_string_literal: true

require "test_helper"

class BaliWidgetComponentTest < ComponentTestCase
  # A real Base subclass rather than a stub, so the test exercises the contract
  # the component actually depends on. The i18n readers are overridden so this
  # file needs no locale fixtures.
  class Stock < Bali::Widget::Base
    sized :medium

    def self.title = "Low stock items"
    def self.short_title = "Low stock"
    def self.empty_message = "Nothing running low"

    class_attribute :stub_result

    def call = self.class.stub_result
  end

  def widget(size: :medium, count: 2, items: nil, view_all_path: "/items",
             payload: nil, failed: false)
    rows = items || [
      Bali::Widget::Row.new(title: "Tomatoes", subtitle: "3 left · Cocina", href: "/i/1"),
      Bali::Widget::Row.new(title: "Onions")
    ]
    Stock.stub_result = Bali::Widget::Result.new(count: count, items: rows,
                                                 view_all_path: view_all_path,
                                                 payload: payload, failed: failed)
    Stock.new.with_size(size)
  end

  def test_renders_the_card_with_its_identity_attributes
    render_inline(Bali::Widget::Component.new(widget))

    assert_selector("section[data-widget-key='stock'][data-size='medium']")
    assert_selector("section[data-id='stock'][data-widget-title='Low stock']")
  end

  def test_the_card_names_itself_for_landmark_navigation
    render_inline(Bali::Widget::Component.new(widget))

    assert_selector("section[aria-label='Low stock']")
  end

  def test_medium_renders_the_title_and_three_rows
    render_inline(Bali::Widget::Component.new(widget(size: :medium, items: 5.times.map { |i|
      Bali::Widget::Row.new(title: "Row #{i}")
    })))

    assert_text("Low stock items")
    assert_selector("ul.list li", count: 3)
  end

  def test_large_renders_seven_rows
    render_inline(Bali::Widget::Component.new(widget(size: :large, items: 9.times.map { |i|
      Bali::Widget::Row.new(title: "Row #{i}")
    })))

    assert_selector("ul.list li", count: 7)
  end

  def test_wide_renders_three_rows_like_medium_because_it_is_one_row_tall
    render_inline(Bali::Widget::Component.new(widget(size: :wide, items: 9.times.map { |i|
      Bali::Widget::Row.new(title: "Row #{i}")
    })))

    assert_selector("ul.list li", count: 3)
  end

  def test_small_renders_a_stat_and_no_rows
    render_inline(Bali::Widget::Component.new(widget(size: :small)))

    assert_selector("a.stat .stat-value", text: "2")
    assert_selector(".stat-title", text: "Low stock")
    assert_no_selector("ul.list")
  end

  def test_a_zero_count_small_card_dims_the_number
    render_inline(Bali::Widget::Component.new(widget(size: :small, count: 0)))

    assert_selector(".stat-value.text-base-content\\/30", text: "0")
  end

  def test_a_small_card_without_a_destination_is_not_a_link_to_nowhere
    render_inline(Bali::Widget::Component.new(widget(size: :small, view_all_path: nil)))

    assert_selector(".stat-value", text: "2")
    # `href="#"` looks clickable and does nothing — the same lie as a retry
    # button that re-runs a broken query.
    assert_no_selector("a[href='#']")
    assert_no_selector("a.stat")
  end

  def test_empty_list_renders_the_empty_message
    render_inline(Bali::Widget::Component.new(widget(count: 0, items: [])))

    assert_text("Nothing running low")
    assert_no_selector("ul.list")
  end

  def test_view_all_link_is_suppressed_when_there_is_nothing_to_view
    render_inline(Bali::Widget::Component.new(widget(count: 0, items: [])))

    assert_no_link(href: "/items")
  end

  def test_failed_widget_says_so_at_every_size
    %i[small medium large wide].each do |size|
      render_inline(Bali::Widget::Component.new(widget(size: size, count: 0, failed: true)))

      assert_text("Couldn't load", count: 1)
      # The confident grey zero is exactly what a failure must never render.
      assert_no_selector(".stat-value")
    end
  end

  def test_body_slot_replaces_the_list
    render_inline(Bali::Widget::Component.new(widget)) do |card|
      card.with_body { "<p class='verdict'>All clear</p>".html_safe }
    end

    assert_selector("p.verdict", text: "All clear")
    assert_no_selector("ul.list")
  end

  def test_body_slot_still_yields_to_the_summary_at_small
    render_inline(Bali::Widget::Component.new(widget(size: :small))) do |card|
      card.with_body { "<p class='verdict'>All clear</p>".html_safe }
    end

    assert_no_selector("p.verdict")
    assert_selector(".stat-value", text: "2")
  end

  def test_renders_a_size_radio_per_size_with_the_current_one_checked
    render_inline(Bali::Widget::Component.new(widget(size: :wide)))

    assert_selector("[role='radiogroup']", visible: :all)
    assert_selector("button[role='radio'][data-widget-size]", count: 4, visible: :all)
    assert_selector("button[data-widget-size='wide'][aria-checked='true']", visible: :all)
    assert_selector("button[data-widget-size='small'][aria-checked='false']", visible: :all)
  end

  # The four sizes are mutually exclusive, so the whole group is ONE tab stop
  # and the checked size is it. Without this a keyboard user tabs through four
  # buttons per card — 48 stops in a twelve-card grid — to reach the next card.
  def test_the_size_group_is_one_tab_stop_carried_by_the_checked_size
    render_inline(Bali::Widget::Component.new(widget(size: :wide)))

    assert_selector("button[data-widget-size='wide'][tabindex='0']", visible: :all)
    assert_selector("button[data-widget-size][tabindex='-1']", count: 3, visible: :all)
  end

  # Selection follows focus, so the arrows have to reach the controller rather
  # than scrolling the page. Bound on the GROUP, not each button: the handler
  # needs the whole set to know what "next" means.
  def test_the_size_group_routes_arrow_keys_to_the_controller
    render_inline(Bali::Widget::Component.new(widget))

    assert_selector(
      "[role='radiogroup'][data-action='keydown->bali-widget-grid#sizeKeydown']", visible: :all
    )
  end

  def test_edit_chrome_is_always_rendered_so_entering_edit_mode_costs_no_round_trip
    render_inline(Bali::Widget::Component.new(widget))

    assert_selector("button.handle[data-action='keydown->bali-widget-grid#move']", visible: :all)
    assert_selector("button[data-action='bali-widget-grid#remove']", visible: :all)
  end

  def test_cell_class_marks_the_filled_cells_of_each_size
    component = Bali::Widget::Component.new(widget)

    assert_includes component.cell_class(:large, 5), "bg-base-content/45"
    assert_includes component.cell_class(:large, 2), "bg-base-content/20"
  end
end
