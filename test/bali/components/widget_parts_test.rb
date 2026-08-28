# frozen_string_literal: true

require "test_helper"

# ONE CARD PER WIDGET TYPE. `Bali::Widget::Component` is the shell — the section,
# its drag and resize contract, the edit chrome and the degraded tile — and these
# are the bodies it dispatches to.
#
# Driven directly rather than through the shell, because the rules they carry (a
# muted zero, a clamped ring, a ternary check, a truncating row) were previously
# reachable only through a full card render three layers away from where they
# live.
class BaliWidgetCardsTest < ComponentTestCase
  HERO = { layout: :hero, context: nil, rows: 0 }.freeze
  INLINE = { layout: :inline, context: :spark, rows: 3 }.freeze
  STACKED = { layout: :stacked, context: :full, rows: 7 }.freeze

  def value_widget(value: 42, **overrides)
    build(Bali::Widget::ValueBase, **overrides) { value { value } }
  end

  def build(base, title: "Low stock", &block)
    klass = Class.new(base) do
      def self.key = "stock"
      empty_message "Nothing running low"
    end
    klass.class_eval { title(title); short_title(title) }
    klass.class_eval(&block)
    klass.new
  end

  # ---- Value ---------------------------------------------------------------

  def test_the_figure_is_the_headline
    render_inline(Bali::Widget::Value::Component.new(value_widget, region: STACKED))

    assert_text "42"
  end

  # A confident black zero and an all-clear zero look identical, so the card dims
  # the one that means nothing happened.
  def test_a_widget_with_nothing_to_report_is_dimmed
    render_inline(Bali::Widget::Value::Component.new(value_widget(value: 0), region: STACKED))

    assert_selector "[class*='text-base-content/30']"
  end

  def test_the_hero_figure_is_a_size_step_larger
    render_inline(Bali::Widget::Value::Component.new(value_widget, region: HERO))

    assert_selector ".stat-value.text-4xl", text: "42"
    assert_no_selector "h5"
  end

  # ---- List ----------------------------------------------------------------

  def list_widget(rows: 9)
    build(Bali::Widget::ListBase) do
      row { |r| r.title :name }
      list { Studio.limit(rows) }
    end
  end

  def test_the_card_truncates_to_what_the_canvas_has_room_for
    12.times { |i| Studio.create!(name: "S#{i}", country: "US") }

    render_inline(Bali::Widget::List::Component.new(list_widget, region: INLINE))
    assert_selector "li", count: 3

    render_inline(Bali::Widget::List::Component.new(list_widget, region: STACKED))
    assert_selector "li", count: 7
  end

  # ---- Trend ---------------------------------------------------------------

  def trend_widget(current: 12, previous: 6, values: [ 1, 4, 2 ])
    build(Bali::Widget::TrendBase) do
      trend { |t| t.current current; t.previous previous }
      series { |s| s.values values } if values
    end
  end

  def test_the_indicator_sits_beside_the_figure_and_under_it_on_the_hero
    render_inline(Bali::Widget::Trend::Component.new(trend_widget, region: STACKED))
    assert_selector ".flex.items-center.gap-3 .text-success", visible: :all

    render_inline(Bali::Widget::Trend::Component.new(trend_widget, region: HERO))
    assert_selector "p.mt-1.flex.justify-center .text-success", visible: :all
  end

  # A sparkline is a chart that has given up its axes, not a different component.
  def test_the_chart_drops_its_axes_below_large
    render_inline(Bali::Widget::Trend::Component.new(trend_widget, region: INLINE))
    spark = JSON.parse(page.find("canvas.chart", visible: :all)[:"data-chart-options-value"])

    assert_equal false, spark.dig("scales", "x", "display")

    render_inline(Bali::Widget::Trend::Component.new(trend_widget, region: STACKED))
    full = JSON.parse(page.find("canvas.chart", visible: :all)[:"data-chart-options-value"])

    refute_equal false, full.dig("scales", "x", "display")
  end

  def test_a_trend_with_no_series_draws_no_chart
    render_inline(Bali::Widget::Trend::Component.new(trend_widget(values: nil), region: STACKED))

    assert_no_selector "canvas.chart", visible: :all
  end

  # ---- Progress ------------------------------------------------------------

  def progress_widget(value: 7, max: 10)
    build(Bali::Widget::ProgressBase) { goal { |g| g.value value; g.max max } }
  end

  # CLAMPED for drawing only: 11 of 10 shifts covered is a real and good state
  # that a ring has nowhere to put, so the arc stops at full while the value
  # still reads true.
  def test_the_ring_clamps_without_lying_about_the_value
    render_inline(Bali::Widget::Progress::Component.new(progress_widget(value: 11), region: STACKED))

    assert_selector "[role='progressbar'][aria-valuenow='11']"
  end

  # daisyUI's `.stat` is a GRID, so `text-align` does not move a grid item — the
  # ring sat off to the left of its own label until this wrapper went round it.
  def test_the_hero_ring_is_centred_by_a_flex_wrapper
    render_inline(Bali::Widget::Progress::Component.new(progress_widget, region: HERO))

    assert_selector "div.flex.justify-center [role='progressbar']"
  end

  # ---- Check ---------------------------------------------------------------

  def check_widget(state)
    build(Bali::Widget::CheckBase) { check { |c| c.value state; c.pass "Healthy"; c.fail "Failing" } }
  end

  # TERNARY: `nil` is "not checked yet" and draws muted, which says something
  # different from a check that answered no.
  def test_a_check_draws_three_states
    { true => "text-success", false => "text-error", nil => "text-base-content/40" }.each do |state, colour|
      render_inline(Bali::Widget::Check::Component.new(check_widget(state), region: STACKED))

      assert_selector ".boolean-icon-component[class*='#{colour}']"
    end
  end

  # Colour alone separating pass from fail is WCAG 1.4.1, so the label is
  # announced as well as printed — in the widget's own words.
  def test_the_label_is_both_announced_and_printed
    render_inline(Bali::Widget::Check::Component.new(check_widget(false), region: HERO))

    assert_selector ".sr-only", text: "Failing"
    assert_selector ".stat-value", text: "Failing"
  end

  # ---- Rows ----------------------------------------------------------------

  def test_a_row_links_when_it_has_somewhere_to_go
    rows = [ Bali::Widget::ListBase::Row.new(title: "Flour", subtitle: "3 left", href: "/items/1"),
             Bali::Widget::ListBase::Row.new(title: "Sugar") ]
    render_inline(Bali::Widget::Rows::Component.new(rows))

    assert_selector "a[href='/items/1']", text: "Flour"
    assert_selector "p", text: "Sugar"
    assert_no_selector "a", text: "Sugar"
  end

  # `min-w-0` is what makes `truncate` work inside a flex row: a flex item's
  # default `min-width:auto` refuses to shrink below its content, so without it a
  # long title pushes through the card's edge instead of being cut. It looks fine
  # until a long title arrives, which is why it is asserted.
  def test_a_row_can_truncate
    render_inline(Bali::Widget::Rows::Component.new([ Bali::Widget::ListBase::Row.new(title: "A" * 200) ]))

    assert_selector ".list-col-grow.min-w-0 .truncate"
  end
end
