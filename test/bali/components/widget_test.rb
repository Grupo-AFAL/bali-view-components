# frozen_string_literal: true

require "test_helper"

class BaliWidgetComponentTest < ComponentTestCase
  # Real pattern subclasses rather than stubs, so the test exercises the contract
  # the card actually depends on: one uniform interface, with each pattern
  # answering only what it has.
  def list_widget(size: :medium, rows: 2, **overrides)
    build(Bali::Widget::ListBase, size, **overrides) do
      order_by :name
      row_title :name
      row_subtitle :country
      view_all_path { "/studios" }
      define_method(:scope) { rows.zero? ? Studio.none : Studio.limit(rows) }
    end
  end

  def value_widget(size: :small, value: 2, **overrides)
    build(Bali::Widget::ValueBase, size, **overrides) do
      supports(*Bali::Widget::SIZES)
      define_method(:value) { value }
    end
  end

  def trend_widget(size: :medium, current: 12, previous: 6, series: [ 1, 4, 2 ], **overrides)
    build(Bali::Widget::TrendBase, size, **overrides) do
      series_values { series } if series
      define_method(:current) { current }
      define_method(:previous) { previous }
    end
  end

  def progress_widget(size: :large, series: [ 3, 4 ], **overrides)
    build(Bali::Widget::ProgressBase, size, **overrides) do
      goal_label { "of 10" }
      series_values { series } if series
      def value = 7
      def max = 10
    end
  end

  def build(base, size, title: "Low stock", &block)
    klass = Class.new(base) do
      def self.key = "stock"
      title title
      short_title title
      empty_message "Nothing running low"
    end
    klass.class_eval { title(title); short_title(title) }
    klass.class_eval(&block)
    klass.default_size(size)
    klass.new.with_size(size)
  end

  setup do
    9.times { |i| Studio.create!(name: "Studio #{i}", country: "MX", status: :active) }
  end

  # ---- identity ------------------------------------------------------------

  def test_renders_the_card_with_its_identity_attributes
    render_inline(Bali::Widget::Component.new(list_widget))

    assert_selector("section[data-widget-key='stock'][data-size='medium']")
    assert_selector("section[data-id='stock'][data-widget-title='Low stock']")
    assert_selector("section#bali-widget-stock")
  end

  def test_the_card_names_itself_for_landmark_navigation
    render_inline(Bali::Widget::Component.new(list_widget))

    assert_selector("section[aria-label='Low stock']")
  end

  # ---- the list ladder -----------------------------------------------------

  def test_medium_renders_the_title_and_three_rows
    render_inline(Bali::Widget::Component.new(list_widget(size: :medium, rows: 8)))

    assert_selector("h5", text: "Low stock")
    assert_selector("ul.list li", count: 3)
  end

  def test_large_renders_seven_rows
    render_inline(Bali::Widget::Component.new(list_widget(size: :large, rows: 8)))

    assert_selector("ul.list li", count: 7)
  end

  def test_empty_list_renders_the_empty_message
    render_inline(Bali::Widget::Component.new(list_widget(rows: 0)))

    assert_text "Nothing running low"
  end

  def test_view_all_link_is_suppressed_when_there_is_nothing_to_view
    render_inline(Bali::Widget::Component.new(list_widget(rows: 0)))

    assert_no_link(href: "/studios")
  end

  # ---- the hero ------------------------------------------------------------

  def test_small_renders_a_stat_and_no_rows
    render_inline(Bali::Widget::Component.new(value_widget(size: :small, value: 2)))

    assert_selector(".stat-value", text: "2")
    assert_no_selector("ul.list li")
  end

  def test_a_zero_count_small_card_dims_the_number
    render_inline(Bali::Widget::Component.new(value_widget(value: 0)))

    assert_selector(".stat-value.text-base-content\\/30", text: "0")
  end

  # `href="#"` would make the card look clickable while doing nothing.
  def test_a_small_card_without_a_destination_is_not_a_link_to_nowhere
    render_inline(Bali::Widget::Component.new(value_widget))

    assert_no_selector("a.stat")
    assert_selector("div.stat")
  end

  # A small widget supports exactly ONE tap target, and the failure is silent for
  # anyone not using a keyboard.
  def test_the_small_card_contains_no_focusable_element_inside_its_single_link
    render_inline(Bali::Widget::Component.new(trend_widget(size: :small)))

    body = page.find(".bali-widget-body")

    assert_empty body.all("a, button, input, select, textarea, [tabindex]", visible: :all)
  end

  # ---- the headline survives, which is the ladder's whole promise -----------

  def test_the_headline_survives_every_size
    Bali::Widget::SIZES.each do |size|
      render_inline(Bali::Widget::Component.new(value_widget(size: size, value: 42)))

      assert page.has_text?("42"), "the headline vanished at #{size}"
    end
  end

  def test_a_large_count_is_abbreviated_so_it_fits_the_tile
    render_inline(Bali::Widget::Component.new(value_widget(value: 1_234_567)))

    assert_selector(".stat-value", text: "1.2M")
  end

  # ---- the degraded card ---------------------------------------------------

  # Checked before the size split, because a failed widget has `count: 0` and a
  # confident grey "0" is this dashboard's word for "all clear".
  #
  # The widget RAISES rather than declaring `failed? = true`, and that difference
  # is the whole test. A widget reads lazily, so at the moment the card asks
  # `failed?` nothing has been loaded and nothing has failed yet — an overridden
  # `failed?` answers true anyway and hides that. This one only reports true if
  # `Base#failed?` actually probes, which is what makes a real broken widget
  # render the apology instead of a confident grey zero.
  def test_a_raising_widget_says_so_at_every_size
    failing = Class.new(Bali::Widget::ValueBase) do
      def self.key = "stock"
      supports(*Bali::Widget::SIZES)
      def value = raise("upstream is down")
    end

    swallowing_load_errors do
      Bali::Widget::SIZES.each do |size|
        render_inline(Bali::Widget::Component.new(failing.new.with_size(size)))

        assert_text "Couldn't load", count: 1
        refute_selector ".stat-value"
      end
    end
  end

  # A widget that half-loaded is in an unknown state, so the whole tile
  # apologises rather than printing a headline it cannot corroborate. This is
  # what moving the load into `before_render` bought: both reads happen before
  # the card's first branch, so there is no such thing as a partly-drawn card
  # that discovers its own failure halfway down.
  def test_a_widget_whose_rows_fail_degrades_the_whole_tile
    half_broken = Class.new(Bali::Widget::ListBase) do
      def self.key = "stock"
      # Breaks where a real list widget breaks: `count` is its own query, and
      # this one succeeds. The rows come from a second read that does not.
      row_title { |_record| raise "row source is down" }
      def count = 12
      def scope = Struct.new(:rows) { def limit(n) = [ :a, :b ].first(n) }.new([])
    end

    swallowing_load_errors do
      render_inline(Bali::Widget::Component.new(half_broken.new.with_size(:large)))

      assert_text "Couldn't load"
      refute_selector "ul.list li"
    end
  end

  # `before_render` loads `count` and the rows, because those are what every
  # card reads. A series is read later, while the context region is being built
  # — so this failure genuinely arrives after the first branch, and the detail
  # region is what is left to carry the apology. Dropping that region (it has no
  # rows and no empty state to show) would drop the message with it.
  def test_a_late_failure_still_finds_a_region_to_apologise_in
    late = Class.new(Bali::Widget::TrendBase) do
      def self.key = "stock"
      series_values { raise "history is down" }
      def current = 12
      def previous = 6
    end

    swallowing_load_errors do
      render_inline(Bali::Widget::Component.new(late.new.with_size(:large)))

      assert_selector(".bali-widget-detail", text: "Couldn't load")
    end
  end

  # ---- trend ---------------------------------------------------------------

  def test_a_trend_renders_beside_the_headline_at_every_size
    Bali::Widget::SIZES.each do |size|
      render_inline(Bali::Widget::Component.new(trend_widget(size: size)))

      assert_selector(".text-success", text: "100%", visible: :all)
    end
  end

  # ---- the chart -----------------------------------------------------------

  def test_a_series_becomes_a_chart_from_medium_up
    %i[medium large].each do |size|
      render_inline(Bali::Widget::Component.new(trend_widget(size: size)))

      assert_selector("canvas.chart", visible: :all, count: 1)
    end
  end

  def test_small_has_no_room_for_a_chart_even_when_one_is_offered
    render_inline(Bali::Widget::Component.new(trend_widget(size: :small)))

    assert_no_selector("canvas.chart", visible: :all)
  end

  # Below roughly 2x2 a chart's axes cost more room than they explain.
  def test_the_chart_drops_its_axes_at_medium_and_keeps_them_at_large
    render_inline(Bali::Widget::Component.new(trend_widget(size: :medium)))

    assert_equal false, chart_options.dig("scales", "x", "display")

    render_inline(Bali::Widget::Component.new(trend_widget(size: :large)))

    refute_equal false, chart_options.dig("scales", "x", "display")
  end

  # Widget series are usually COUNTS, and Chart.js will happily offer "1.6" of
  # them.
  def test_a_chart_of_whole_numbers_gets_whole_numbered_ticks
    render_inline(Bali::Widget::Component.new(trend_widget(size: :large)))

    assert_equal 0, chart_options.dig("scales", "y", "ticks", "precision")
  end

  def test_a_chart_of_fractions_is_left_alone
    render_inline(Bali::Widget::Component.new(trend_widget(size: :large, series: [ 1.5, 2.25 ])))

    assert_nil chart_options.dig("scales", "y", "ticks", "precision")
  end

  # ---- the ring ------------------------------------------------------------

  def test_a_goal_replaces_the_number_as_the_headline
    render_inline(Bali::Widget::Component.new(progress_widget(size: :small)))

    assert_selector("[role='progressbar'][aria-valuenow='7']", visible: :all)
    assert_no_selector(".stat-value")
  end

  def test_a_goal_keeps_its_ring_and_gains_a_chart_as_the_card_grows
    render_inline(Bali::Widget::Component.new(progress_widget(size: :large)))

    assert_selector("[role='progressbar']", visible: :all)
    assert_selector("canvas.chart", visible: :all)
  end

  # ---- regions -------------------------------------------------------------

  # `rows` is a pixel budget measured against Bali's own type sizes; a host with
  # a larger base font had no way to say so.
  def test_the_row_budget_can_be_overridden_by_a_host
    original = Bali::Widget::Component.regions
    Bali::Widget::Component.regions = original.deep_merge(large: { rows: 2 })

    render_inline(Bali::Widget::Component.new(list_widget(size: :large, rows: 8)))

    assert_selector("ul.list li", count: 2)
  ensure
    Bali::Widget::Component.regions = original
  end

  # A region sized for content the widget never supplied leaves the card holding
  # whitespace — the defect that bit three rounds running.
  def test_a_widget_with_no_rows_renders_no_detail_region
    render_inline(Bali::Widget::Component.new(trend_widget(size: :large)))

    assert_no_selector(".bali-widget-detail")
  end

  def test_the_chart_takes_the_whole_column_when_no_breakdown_sits_under_it
    render_inline(Bali::Widget::Component.new(trend_widget(size: :large)))

    assert_selector(".bali-widget-context.flex-1")
  end

  # ---- the body slot -------------------------------------------------------

  def test_body_slot_replaces_the_list
    render_inline(Bali::Widget::Component.new(list_widget)) do |card|
      card.with_body { "<p class='verdict'>All clear</p>".html_safe }
    end

    assert_selector("p.verdict")
    assert_no_selector("ul.list li")
  end

  def test_body_slot_still_yields_to_the_summary_at_small
    render_inline(Bali::Widget::Component.new(value_widget(size: :small))) do |card|
      card.with_body { "<p class='verdict'>All clear</p>".html_safe }
    end

    assert_no_selector("p.verdict")
    assert_selector(".stat-value", text: "2")
  end

  # A slot filled at the call site is an explicit instruction; a series is a data
  # field. At `:inline` there is room for one of them.
  def test_a_filled_body_slot_beats_the_chart_where_only_one_fits
    render_inline(Bali::Widget::Component.new(trend_widget(size: :medium))) do |card|
      card.with_body { "<p class='verdict'>All clear</p>".html_safe }
    end

    assert_selector("p.verdict")
    assert_no_selector("canvas.chart", visible: :all)
  end

  def test_the_chart_still_wins_when_no_slot_asked_for_the_space
    render_inline(Bali::Widget::Component.new(trend_widget(size: :medium)))

    assert_selector("canvas.chart", visible: :all)
  end

  # ---- edit chrome ---------------------------------------------------------

  def test_the_card_mounts_the_size_picker_for_its_own_widget
    render_inline(Bali::Widget::Component.new(list_widget(size: :large)))

    assert_selector("[role='radiogroup'][aria-label='Size of Low stock']", visible: :all)
    assert_selector("button[data-widget-size='large'][aria-checked='true']", visible: :all)
  end

  def test_the_picker_offers_only_the_sizes_the_widget_supports
    limited = Class.new(Bali::Widget::ListBase) do
      def self.key = "stock"
      default_size :small
      supports :small, :medium
      row_title :name
      def scope = Studio.all
    end

    render_inline(Bali::Widget::Component.new(limited.new.with_size(:small)))

    assert_selector("button[data-widget-size]", count: 2, visible: :all)
    assert_no_selector("button[data-widget-size='large']", visible: :all)
  end

  # A radiogroup with one option is not a choice — and `ValueBase` supports one
  # size by default, which is the class's whole point.
  def test_a_widget_with_one_size_gets_no_picker_at_all
    fixed = Class.new(Bali::Widget::ValueBase) { def self.key = "stock"; def value = 1 }

    render_inline(Bali::Widget::Component.new(fixed.new))

    assert_no_selector("[role='radiogroup']", visible: :all)
  end

  def test_edit_chrome_is_always_rendered_so_entering_edit_mode_costs_no_round_trip
    render_inline(Bali::Widget::Component.new(list_widget))

    assert_selector("button.handle[data-action='keydown->bali-widget-grid#move']", visible: :all)
    assert_selector("button[data-action='bali-widget-grid#remove']", visible: :all)
  end

  # Read off the rendered canvas rather than the component: this is the value
  # Chart.js actually receives.
  def chart_options
    JSON.parse(page.find("canvas.chart", visible: :all)["data-chart-options-value"])
  end

  private

  # `raise_load_errors?` is a method rather than a constant precisely so a test
  # can swap it: the safety net is OFF in development, so a test that wants to
  # see the degraded card has to ask for production's behaviour.
  def swallowing_load_errors
    original = Bali::Widget.method(:raise_load_errors?)
    Bali::Widget.define_singleton_method(:raise_load_errors?) { false }
    yield
  ensure
    Bali::Widget.define_singleton_method(:raise_load_errors?, original)
  end
end
