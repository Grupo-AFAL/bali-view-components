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
             payload: nil, failed: false, display_value: nil, trend: nil,
             series: nil, goal: nil)
    rows = items || [
      Bali::Widget::Row.new(title: "Tomatoes", subtitle: "3 left · Cocina", href: "/i/1"),
      Bali::Widget::Row.new(title: "Onions")
    ]
    Stock.stub_result = Bali::Widget::Result.new(count: count, items: rows,
                                                 view_all_path: view_all_path,
                                                 payload: payload, failed: failed,
                                                 display_value: display_value, trend: trend,
                                                 series: series, goal: goal)
    Stock.new.with_size(size)
  end

  def a_series = Bali::Widget::Series.new(values: [ 1, 4, 2, 8 ], labels: %w[a b c d])

  def a_trend(**overrides) = Bali::Widget::Trend.new(**{ delta: 12 }.merge(overrides))

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

  # `wide` is 4x2 now, not 4x1 — Apple's extra large, defined as two mediums
  # side by side. As 4x1 it was the ladder's weakest cell: three rows stretched
  # across four columns, showing LESS than `medium` in four times the space.
  def test_wide_renders_six_rows_because_it_is_two_rows_tall
    render_inline(Bali::Widget::Component.new(widget(size: :wide, items: 9.times.map { |i|
      Bali::Widget::Row.new(title: "Row #{i}")
    })))

    assert_selector("ul.list li", count: 6)
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

  # The picker is its own component now; its behaviour is tested there. This
  # only asserts the card still mounts it, named for the widget it sizes.
  def test_the_card_mounts_the_size_picker_for_its_own_widget
    render_inline(Bali::Widget::Component.new(widget(size: :wide)))

    assert_selector("[role='radiogroup'][aria-label='Size of Low stock']", visible: :all)
    assert_selector("button[data-widget-size='wide'][aria-checked='true']", visible: :all)
  end

  def test_edit_chrome_is_always_rendered_so_entering_edit_mode_costs_no_round_trip
    render_inline(Bali::Widget::Component.new(widget))

    assert_selector("button.handle[data-action='keydown->bali-widget-grid#move']", visible: :all)
    assert_selector("button[data-action='bali-widget-grid#remove']", visible: :all)
  end

  # ==========================================================================
  # The size ladder. The card must show the SAME FACT at every size and give it
  # more context as it grows — never change subject. These are the assertions
  # that hold it to that.
  # ==========================================================================

  # THE REGRESSION THE LADDER EXISTS TO FIX. The headline used to appear at
  # `small` and nowhere else: at `medium` it was replaced by a list, which is
  # substitution rather than disclosure.
  def test_the_headline_survives_every_size
    Bali::Widget::SIZES.each do |size|
      render_inline(Bali::Widget::Component.new(widget(size: size, count: 42)))

      assert page.has_text?("42"), "the headline vanished at #{size}"
    end
  end

  def test_a_trend_renders_beside_the_headline_at_every_size
    Bali::Widget::SIZES.each do |size|
      render_inline(Bali::Widget::Component.new(widget(size: size, trend: a_trend)))

      assert_selector(".text-success", text: "12%", visible: :all)
    end
  end

  # COLOUR COMES FROM `good?`, NEVER `direction`. Overdue tasks up 12% and
  # revenue up 12% are opposite news, and a card reading the direction would
  # paint half a dashboard's trends the wrong way while looking confident.
  def test_a_rising_trend_is_red_when_the_widget_says_rising_is_bad
    render_inline(Bali::Widget::Component.new(
      widget(trend: a_trend(delta: 12, positive_when: :down))
    ))

    assert_selector(".text-error", visible: :all)
    assert_no_selector(".text-success", visible: :all)
  end

  def test_a_flat_trend_is_neither_good_nor_bad
    render_inline(Bali::Widget::Component.new(widget(trend: a_trend(delta: 0))))

    assert_no_selector(".text-success", visible: :all)
    assert_no_selector(".text-error", visible: :all)
  end

  # The arrow is decorative; the direction has to reach a screen reader as a
  # WORD or the trend announces as a bare number.
  def test_the_trend_direction_is_announced_as_words_not_an_arrow
    render_inline(Bali::Widget::Component.new(widget(trend: a_trend)))

    assert_selector(".sr-only", text: "up 12%", visible: :all)
  end

  # ---- the context region --------------------------------------------------

  def test_a_series_becomes_a_chart_from_medium_up
    %i[medium large wide].each do |size|
      render_inline(Bali::Widget::Component.new(widget(size: size, series: a_series)))

      assert_selector("canvas.chart", visible: :all, count: 1)
    end
  end

  def test_small_has_no_room_for_a_chart_even_when_one_is_offered
    render_inline(Bali::Widget::Component.new(widget(size: :small, series: a_series)))

    assert_no_selector("canvas.chart", visible: :all)
  end

  # Below roughly 2x2 a chart's axes cost more room than they explain, which is
  # what makes `medium`'s chart a sparkline and `large`'s a chart.
  def test_the_chart_drops_its_axes_at_medium_and_keeps_them_at_large
    render_inline(Bali::Widget::Component.new(widget(size: :medium, series: a_series)))

    assert_equal false, chart_options.dig("scales", "x", "display")

    render_inline(Bali::Widget::Component.new(widget(size: :large, series: a_series)))

    refute_equal false, chart_options.dig("scales", "x", "display")
  end

  # Read off the rendered canvas rather than the component: this is the value
  # Chart.js actually receives, so it survives any refactor of how it is built.
  def chart_options
    JSON.parse(page.find("canvas.chart", visible: :all)["data-chart-options-value"])
  end

  # ---- degradation, which is what keeps every pre-ladder widget working ------

  # A widget supplying neither series nor goal — every widget written against
  # the original contract — must render exactly what it always did.
  def test_a_widget_with_no_ladder_data_keeps_its_original_row_counts
    { medium: 3, large: 7 }.each do |size, expected|
      render_inline(Bali::Widget::Component.new(widget(size: size, items: 9.times.map { |i|
        Bali::Widget::Row.new(title: "Row #{i}")
      })))

      assert_selector("ul.list li", count: expected)
    end
  end

  # And a widget that DOES chart trades rows for the chart rather than growing
  # the tile.
  def test_a_charted_widget_trades_rows_for_the_chart
    render_inline(Bali::Widget::Component.new(widget(size: :large, series: a_series,
                                                     items: 9.times.map { |i|
                                                       Bali::Widget::Row.new(title: "Row #{i}")
                                                     })))

    assert_selector("ul.list li", count: 3)
  end

  # ---- the goal ladder -----------------------------------------------------

  def test_a_goal_replaces_the_number_as_the_headline
    render_inline(Bali::Widget::Component.new(
      widget(size: :small, goal: Bali::Widget::Goal.new(value: 7, max: 10, label: "shifts"))
    ))

    assert_selector("[role='progressbar'][aria-valuenow='7']", visible: :all)
    assert_no_selector(".stat-value")
  end

  # A GOAL IS A HEADLINE, NOT A CONTEXT. The context region can only ever draw
  # a series, so counting a goal as context made the card reserve room for a
  # chart that never renders: at `medium` the detail region was suppressed
  # entirely and the tile showed a ring and nothing else, where the same widget
  # without a goal showed three rows.
  def test_a_goal_without_a_series_does_not_cost_the_card_its_rows
    render_inline(Bali::Widget::Component.new(
      widget(size: :medium, goal: Bali::Widget::Goal.new(value: 7, max: 10),
             items: 9.times.map { |i| Bali::Widget::Row.new(title: "Row #{i}") })
    ))

    assert_selector("ul.list li", count: 3)
  end

  def test_a_goal_without_a_series_keeps_the_full_row_count_at_large
    render_inline(Bali::Widget::Component.new(
      widget(size: :large, goal: Bali::Widget::Goal.new(value: 7, max: 10),
             items: 9.times.map { |i| Bali::Widget::Row.new(title: "Row #{i}") })
    ))

    assert_selector("ul.list li", count: 7)
  end

  # And the empty state survives too: it was gated on `!context?`, so a goal
  # widget with nothing to list said nothing at all.
  def test_a_goal_widget_with_nothing_to_list_still_says_so
    render_inline(Bali::Widget::Component.new(
      widget(size: :large, count: 0, items: [],
             goal: Bali::Widget::Goal.new(value: 0, max: 10))
    ))

    assert_text "Nothing running low"
  end

  # THE SAME DEFECT AS `context?`, on the other side of the card: a region sized
  # for content the widget never supplied. The number and ring ladders are
  # DOCUMENTED as having no items, so the detail wrapper rendered empty — taking
  # `flex-1` at `:stacked` and squeezing the chart into two fifths of a canvas it
  # could have had whole, and leaving a blank right-hand column at `:split`.
  #
  # Shaped after the example in docs/guides/components.md.
  # DECIDED, not accidental: a slot filled at the call site is an explicit
  # instruction from the host; a `series` is a data field. At `:inline` there is
  # room for the headline and one of them, so the explicit one wins. Before this,
  # a widget that asked for custom content silently got a sparkline instead.
  def test_a_filled_body_slot_beats_the_chart_where_only_one_fits
    render_inline(Bali::Widget::Component.new(widget(size: :medium, series: a_series))) do |card|
      card.with_body { "<p class='verdict'>All clear</p>".html_safe }
    end

    assert_selector("p.verdict")
    assert_no_selector("canvas.chart", visible: :all)
  end

  def test_the_chart_still_wins_when_no_slot_asked_for_the_space
    render_inline(Bali::Widget::Component.new(widget(size: :medium, series: a_series)))

    assert_selector("canvas.chart", visible: :all)
  end

  def test_a_widget_with_no_items_renders_no_detail_region
    render_inline(Bali::Widget::Component.new(
      widget(size: :large, count: 7, items: [], series: a_series,
             goal: Bali::Widget::Goal.new(value: 7, max: 10, label: "of 10"))
    ))

    assert_no_selector(".bali-widget-detail")
  end

  # THE THIRD INSTANCE of the same class: a region sized against a neighbour that
  # may not be there. `basis-2/5` has no grow, and two fifths was chosen because
  # the breakdown sits UNDER the chart — so once `detail?` can remove the
  # breakdown, the chart keeps 40% and nothing takes the other 60%. The empty
  # wrapper went away; the whitespace it was holding did not.
  def test_the_chart_takes_the_whole_column_when_no_breakdown_sits_under_it
    render_inline(Bali::Widget::Component.new(
      widget(size: :large, count: 7, items: [], series: a_series,
             goal: Bali::Widget::Goal.new(value: 7, max: 10))
    ))

    assert_selector(".bali-widget-context.flex-1")
    assert_no_selector(".bali-widget-context.basis-2\\/5")
  end

  def test_the_split_layout_drops_its_second_column_when_there_is_no_detail
    render_inline(Bali::Widget::Component.new(
      widget(size: :wide, count: 7, items: [], series: a_series,
             goal: Bali::Widget::Goal.new(value: 7, max: 10))
    ))

    assert_no_selector(".bali-widget-detail")
    assert_no_selector(".lg\\:grid-cols-2")
  end

  def test_a_goal_keeps_its_ring_and_gains_a_chart_as_the_card_grows
    render_inline(Bali::Widget::Component.new(
      widget(size: :large, series: a_series,
             goal: Bali::Widget::Goal.new(value: 7, max: 10))
    ))

    assert_selector("[role='progressbar']", visible: :all)
    assert_selector("canvas.chart", visible: :all)
  end

  # ---- the one-tap-target constraint ---------------------------------------

  # A small widget supports exactly ONE tap target. A trend or a ring rendering
  # a focusable control inside the tile would break that, and the failure is
  # silent for anyone not using a keyboard.
  def test_the_small_card_contains_no_focusable_element_inside_its_single_link
    render_inline(Bali::Widget::Component.new(
      widget(size: :small, trend: a_trend,
             goal: Bali::Widget::Goal.new(value: 7, max: 10))
    ))

    within_body = page.find("a.stat")

    assert_empty within_body.all("a, button, input, select, textarea, [tabindex]", visible: :all)
  end

  # ---- the abbreviation constraint -----------------------------------------

  def test_a_large_count_is_abbreviated_so_it_fits_the_tile
    render_inline(Bali::Widget::Component.new(widget(size: :small, count: 1_234_567)))

    assert_selector(".stat-value", text: "1.2M")
  end

  def test_a_widget_can_override_the_headline_for_a_non_count_metric
    render_inline(Bali::Widget::Component.new(
      widget(size: :small, count: 72, display_value: "72%")
    ))

    assert_selector(".stat-value", text: "72%")
  end
end
