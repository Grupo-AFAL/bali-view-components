# frozen_string_literal: true

require "test_helper"

class BaliWidgetComponentTest < ComponentTestCase
  # Real pattern subclasses rather than stubs, so the test exercises the contract
  # the card actually depends on: one uniform interface, with each pattern
  # answering only what it has.
  def list_widget(size: :medium, rows: 2, **overrides)
    build(Bali::Widget::ListBase, size, **overrides) do
      row do |r|
        r.title :name
        r.subtitle :country
      end
      view_all_path { "/studios" }
      list { rows.zero? ? Studio.none : Studio.order(:name).limit(rows) }
    end
  end

  def value_widget(size: :small, value: 2, **overrides)
    build(Bali::Widget::ValueBase, size, **overrides) do
      supports(*Bali::Widget::SIZES)
      value { value }
    end
  end

  def trend_widget(size: :medium, current: 12, previous: 6, series: [ 1, 4, 2 ], **overrides)
    build(Bali::Widget::TrendBase, size, **overrides) do
      trend do |t|
        t.current current
        t.previous previous
      end
      series { |s| s.values series } if series
    end
  end

  def progress_widget(size: :large, series: [ 3, 4 ], **overrides)
    build(Bali::Widget::ProgressBase, size, **overrides) do
      goal do |g|
        g.value 7
        g.max 10
        g.label "of 10"
      end
      series { |s| s.values series } if series
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
    klass.new
  end

  # The card is TOLD which size to draw. `build` sets `default_size` to match, so
  # a helper's `size:` reaches both the component and anything asking the class.
  # `Rails.env` rather than a switch on `Bali::Widget`: the boundary reads the
  # environment directly, so this is the only way to see what a developer sees.
  def in_development
    original = Rails.env
    Rails.env = "development"
    yield
  ensure
    Rails.env = original
  end

  def card(widget, size: nil, **options)
    Bali::Widget::Component.new(widget, size: size || widget.class.default_size, **options)
  end

  setup do
    9.times { |i| Studio.create!(name: "Studio #{i}", country: "MX", status: :active) }
  end

  # ---- identity ------------------------------------------------------------

  def test_renders_the_card_with_its_identity_attributes
    render_inline(card(list_widget))

    assert_selector("section[data-widget-key='stock'][data-size='medium']")
    assert_selector("section[data-id='stock'][data-widget-title='Low stock']")
    assert_selector("section#bali-widget-stock")
  end

  def test_the_card_names_itself_for_landmark_navigation
    render_inline(card(list_widget))

    assert_selector("section[aria-label='Low stock']")
  end

  # ---- the list ladder -----------------------------------------------------

  def test_medium_renders_the_title_and_three_rows
    render_inline(card(list_widget(size: :medium, rows: 8)))

    assert_selector("h5", text: "Low stock")
    assert_selector("ul.list li", count: 3)
  end

  def test_large_renders_seven_rows
    render_inline(card(list_widget(size: :large, rows: 8)))

    assert_selector("ul.list li", count: 7)
  end

  def test_empty_list_renders_the_empty_message
    render_inline(card(list_widget(rows: 0)))

    assert_text "Nothing running low"
  end

  def test_view_all_link_is_suppressed_when_there_is_nothing_to_view
    render_inline(card(list_widget(rows: 0)))

    assert_no_link(href: "/studios")
  end

  # ---- the hero ------------------------------------------------------------

  def test_small_renders_a_stat_and_no_rows
    render_inline(card(value_widget(size: :small, value: 2)))

    assert_selector(".stat-value", text: "2")
    assert_no_selector("ul.list li")
  end

  def test_a_zero_count_small_card_dims_the_number
    render_inline(card(value_widget(value: 0)))

    assert_selector(".stat-value.text-base-content\\/30", text: "0")
  end

  # `href="#"` would make the card look clickable while doing nothing.
  def test_a_small_card_without_a_destination_is_not_a_link_to_nowhere
    render_inline(card(value_widget))

    assert_no_selector("a.stat")
    assert_selector("div.stat")
  end

  # A small widget supports exactly ONE tap target, and the failure is silent for
  # anyone not using a keyboard.
  def test_the_small_card_contains_no_focusable_element_inside_its_single_link
    render_inline(card(trend_widget(size: :small)))

    body = page.find(".bali-widget-body")

    assert_empty body.all("a, button, input, select, textarea, [tabindex]", visible: :all)
  end

  # ---- the headline survives, which is the ladder's whole promise -----------

  def test_the_headline_survives_every_size
    Bali::Widget::SIZES.each do |size|
      render_inline(card(value_widget(size: size, value: 42)))

      assert page.has_text?("42"), "the headline vanished at #{size}"
    end
  end

  def test_a_large_count_is_abbreviated_so_it_fits_the_tile
    render_inline(card(value_widget(value: 1_234_567)))

    assert_selector(".stat-value", text: "1.2M")
  end

  # ---- the error boundary --------------------------------------------------

  # THE ONE DISTINCTION THE BOUNDARY DRAWS, and it is only observable in
  # development: everywhere else both cases degrade. A plain exception is a BUG
  # and is re-raised where someone can fix it; `Unavailable` is a host saying
  # "my source is down", which is a fact rather than a bug and gives a developer
  # nothing to act on from a stack trace.
  def test_only_a_bug_is_re_raised_in_development
    broken = Class.new(Bali::Widget::ValueBase) do
      def self.key = "stock"
      value { raise "upstream blew up" }
    end
    unavailable = Class.new(Bali::Widget::ValueBase) do
      def self.key = "stock"
      value { raise Bali::Widget::Unavailable, "the feed is down" }
    end

    in_development do
      assert_raises(RuntimeError) { render_inline(card(broken.new)) }

      render_inline(card(unavailable.new))
      assert_text "Couldn't load"
    end
  end

  # And outside development BOTH degrade, because the person looking at the
  # dashboard cannot fix either one and the other tiles are still worth
  # rendering.
  def test_everywhere_else_both_degrade
    broken = Class.new(Bali::Widget::ValueBase) do
      def self.key = "stock"
      value { raise "upstream blew up" }
    end

    render_inline(card(broken.new))

    assert_text "Couldn't load"
  end

  # THE TILE KEEPS ITS IDENTITY. The boundary wraps the CARD, not the whole
  # component, because the section carries `data-widget-key`, the drag handle,
  # the size picker and the `inert` target — unwinding the shell too would leave
  # a failed widget undraggable, unresizable and invisible to the grid.
  def test_a_degraded_tile_is_still_a_tile
    broken = Class.new(Bali::Widget::ValueBase) do
      def self.key = "stock"
      supports(*Bali::Widget::SIZES)
      value { raise Bali::Widget::Unavailable, "down" }
    end

    render_inline(card(broken.new, size: :large))

    assert_selector "section[data-widget-key='stock'][data-size='large']"
    assert_selector ".handle"
    assert_selector "[data-bali-widget-grid-edit-mode-target='inert']"
    assert_text "Couldn't load"
  end

  # The partial card is DISCARDED rather than left above the apology: `render`
  # returns the child's markup as a string, so an exception on the way through
  # means nothing was appended.
  def test_a_failure_mid_render_leaves_no_half_card
    half = Class.new(Bali::Widget::TrendBase) do
      def self.key = "stock"
      trend { |t| t.current 12; t.previous 6 }
      series { |s| s.values { raise Bali::Widget::Unavailable, "history is down" } }
    end

    render_inline(card(half.new, size: :large))

    assert_text "Couldn't load", count: 1
    assert_no_selector "h5"
    assert_no_selector "canvas.chart", visible: :all
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
      value { raise("upstream is down") }
    end

    Bali::Widget::SIZES.each do |size|
      render_inline(card(failing.new, size: size))

      assert_text "Couldn't load", count: 1
      refute_selector ".stat-value"
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
      row do |r|
        r.title { |_record| raise "row source is down" }
      end
      def count = 12
      list { Struct.new(:rows) { def limit(n) = [ :a, :b ].first(n) }.new([]) }
    end

    render_inline(card(half_broken.new, size: :large))

    assert_text "Couldn't load"
    refute_selector "ul.list li"
  end

  # A FAILURE ANYWHERE IN THE RENDER degrades the whole tile, whenever it
  # happens. There is no "early" and "late" any more: the boundary unwinds the
  # subtree, so a series that raises while the chart is being built takes the
  # card with it rather than leaving a headline above an apology.
  #
  # That is a deliberate change from the partial rendering this used to do. A
  # widget that half-loaded is in an unknown state, and a figure you cannot
  # corroborate is the thing the degraded tile exists to avoid printing.
  def test_a_failure_while_rendering_degrades_the_whole_tile
    late = Class.new(Bali::Widget::TrendBase) do
      def self.key = "stock"
      series { |s| s.values { raise "history is down" } }
      trend { |t| t.current 12; t.previous 6 }
    end

    render_inline(card(late.new, size: :large))

    assert_text "Couldn't load", count: 1
    assert_no_selector "canvas.chart", visible: :all
    assert_no_selector "h5"
  end

  # THE `:small` HOLE. A widget missing a required declaration used to render a
  # confident grey `0` at `small` while apologising correctly at the other two
  # sizes — the exact failure the degraded tile exists to prevent, in the default
  # size of the two patterns that carry the most computed logic.
  #
  # The mechanism was size-dependent and worth naming: the hero branch decides on
  # `failed?` at the very top and never looks again, so a guard that only fired
  # from `#trend` or `#goal` was reached AFTER the card had committed to looking
  # healthy. Validating from `count` closes it, because `before_render` reads
  # `count` at every size.
  def test_a_missing_declaration_apologises_at_every_size_including_small
    missing_current = Class.new(Bali::Widget::TrendBase) do
      def self.key = "stock"
      supports(*Bali::Widget::SIZES)
      trend { |t| t.previous 5 }
    end
    missing_value = Class.new(Bali::Widget::ProgressBase) do
      def self.key = "stock"
      supports(*Bali::Widget::SIZES)
      goal { |g| g.max 10 }
    end
    missing_row = Class.new(Bali::Widget::ListBase) do
      def self.key = "stock"
      supports(*Bali::Widget::SIZES)
      list { Studio.all }
    end

    [ missing_current, missing_value, missing_row ].each do |klass|
      Bali::Widget::SIZES.each do |size|
        render_inline(card(klass.new, size: size))

        assert_text "Couldn't load", count: 1
        refute_selector ".stat-value", text: "0"
      end
    end
  end

  # EACH PATTERN RESOLVES WHAT ITS OWN CARD READS, and that list is not the same
  # for all five. A `count` alone is enough for a figure, a list and a check, but
  # not for the two whose headline is built from a second read: a progress widget
  # whose `g.max` raised reported healthy, and the card then handed
  # `Bali::Gauge` a nil goal and took the whole page down with an
  # `ArgumentError`. That is why `#load` is per pattern rather than on `Base`.
  def test_a_second_read_failing_still_degrades_the_tile
    broken_max = Class.new(Bali::Widget::ProgressBase) do
      def self.key = "stock"
      supports(*Bali::Widget::SIZES)
      goal { |g| g.value 5; g.max { raise "max is down" } }
    end
    broken_previous = Class.new(Bali::Widget::TrendBase) do
      def self.key = "stock"
      supports(*Bali::Widget::SIZES)
      trend { |t| t.current 5; t.previous { raise "previous is down" } }
    end

    [ broken_max, broken_previous ].each do |klass|
      Bali::Widget::SIZES.each do |size|
        render_inline(card(klass.new, size: size))

        assert_text "Couldn't load", count: 1
      end
    end
  end

  # ---- trend ---------------------------------------------------------------

  def test_a_trend_renders_beside_the_headline_at_every_size
    Bali::Widget::SIZES.each do |size|
      render_inline(card(trend_widget(size: size)))

      assert_selector(".text-success", text: "100%", visible: :all)
    end
  end

  # ---- the chart -----------------------------------------------------------

  def test_a_series_becomes_a_chart_from_medium_up
    %i[medium large].each do |size|
      render_inline(card(trend_widget(size: size)))

      assert_selector("canvas.chart", visible: :all, count: 1)
    end
  end

  def test_small_has_no_room_for_a_chart_even_when_one_is_offered
    render_inline(card(trend_widget(size: :small)))

    assert_no_selector("canvas.chart", visible: :all)
  end

  # Below roughly 2x2 a chart's axes cost more room than they explain.
  def test_the_chart_drops_its_axes_at_medium_and_keeps_them_at_large
    render_inline(card(trend_widget(size: :medium)))

    assert_equal false, chart_options.dig("scales", "x", "display")

    render_inline(card(trend_widget(size: :large)))

    refute_equal false, chart_options.dig("scales", "x", "display")
  end

  # Widget series are usually COUNTS, and Chart.js will happily offer "1.6" of
  # them.
  def test_a_chart_of_whole_numbers_gets_whole_numbered_ticks
    render_inline(card(trend_widget(size: :large)))

    assert_equal 0, chart_options.dig("scales", "y", "ticks", "precision")
  end

  def test_a_chart_of_fractions_is_left_alone
    render_inline(card(trend_widget(size: :large, series: [ 1.5, 2.25 ])))

    assert_nil chart_options.dig("scales", "y", "ticks", "precision")
  end

  # ---- the ring ------------------------------------------------------------

  def test_a_goal_replaces_the_number_as_the_headline
    render_inline(card(progress_widget(size: :small)))

    assert_selector("[role='progressbar'][aria-valuenow='7']", visible: :all)
    assert_no_selector(".stat-value")
  end

  def test_a_goal_keeps_its_ring_and_gains_a_chart_as_the_card_grows
    render_inline(card(progress_widget(size: :large)))

    assert_selector("[role='progressbar']", visible: :all)
    assert_selector("canvas.chart", visible: :all)
  end

  # ---- the row budget ------------------------------------------------------

  # THE ONE THING A SIZE SAYS that the size itself does not. It is a pixel budget
  # measured against Bali's own type sizes, and a host with a larger base font,
  # two-line subtitles or a denser theme had no way to say so. Everything else a
  # size used to carry — hero, inline, stacked, spark — is one-to-one with the
  # size and is derived rather than tabulated.
  def test_the_row_budget_can_be_overridden_by_a_host
    original = Bali::Widget::Component.rows_budget
    Bali::Widget::Component.rows_budget = original.merge(large: 2)

    render_inline(card(list_widget(size: :large, rows: 8)))

    assert_selector("ul.list li", count: 2)
  ensure
    Bali::Widget::Component.rows_budget = original
  end

  # A region sized for content the widget never supplied leaves the card holding
  # whitespace — the defect that bit three rounds running.
  def test_a_widget_with_no_rows_renders_no_detail_region
    render_inline(card(trend_widget(size: :large)))

    assert_no_selector(".bali-widget-detail")
  end

  def test_the_chart_takes_the_whole_column_when_no_breakdown_sits_under_it
    render_inline(card(trend_widget(size: :large)))

    assert_selector(".bali-widget-context.flex-1")
  end

  # ---- the body slot -------------------------------------------------------

  def test_the_chart_still_wins_when_no_slot_asked_for_the_space
    render_inline(card(trend_widget(size: :medium)))

    assert_selector("canvas.chart", visible: :all)
  end

  # ---- edit chrome ---------------------------------------------------------

  def test_the_card_mounts_the_size_picker_for_its_own_widget
    render_inline(card(list_widget(size: :large)))

    assert_selector("[role='radiogroup'][aria-label='Size of Low stock']", visible: :all)
    assert_selector("button[data-widget-size='large'][aria-checked='true']", visible: :all)
  end

  def test_the_picker_offers_only_the_sizes_the_widget_supports
    limited = Class.new(Bali::Widget::ListBase) do
      def self.key = "stock"
      default_size :small
      supports :small, :medium
      row do |r|
        r.title :name
      end
      def scope = Studio.all
    end

    render_inline(card(limited.new, size: :small))

    assert_selector("button[data-widget-size]", count: 2, visible: :all)
    assert_no_selector("button[data-widget-size='large']", visible: :all)
  end

  # A radiogroup with one option is not a choice — and `ValueBase` supports one
  # size by default, which is the class's whole point.
  def test_a_widget_with_one_size_gets_no_picker_at_all
    fixed = Class.new(Bali::Widget::ValueBase) { def self.key = "stock"; value { 1 } }

    render_inline(card(fixed.new))

    assert_no_selector("[role='radiogroup']", visible: :all)
  end

  def test_edit_chrome_is_always_rendered_so_entering_edit_mode_costs_no_round_trip
    render_inline(card(list_widget))

    assert_selector("button.handle[data-action='keydown->bali-widget-grid#move']", visible: :all)
    assert_selector("button[data-action='bali-widget-grid#remove']", visible: :all)
  end

  # Read off the rendered canvas rather than the component: this is the value
  # Chart.js actually receives.
  def chart_options
    JSON.parse(page.find("canvas.chart", visible: :all)["data-chart-options-value"])
  end

  # ---- self-refresh --------------------------------------------------------

  # BOTH HALVES OR NEITHER. A widget with an interval on a page that gave no URL
  # cannot poll, so the card renders static rather than wiring a dead controller.
  def test_a_card_polls_only_when_it_has_both_an_interval_and_a_url
    volatile = Class.new(Bali::Widget::ValueBase) do
      def self.key = "volatile"
      refresh_every 30.seconds
      value { 7 }
    end

    render_inline(Bali::Widget::Component.new(volatile.new, refresh_url: "/dashboard/refresh"))
    assert_selector "[data-controller~='bali-widget-refresh']"

    render_inline(Bali::Widget::Component.new(volatile.new))
    assert_no_selector "[data-controller~='bali-widget-refresh']"
  end

  # A widget that never asked to refresh must not poll just because the page
  # offered a URL — every card on a dashboard is handed one.
  def test_a_card_without_an_interval_never_polls
    render_inline(card(steady_widget.new, refresh_url: "/dashboard/refresh"))

    assert_no_selector "[data-controller~='bali-widget-refresh']"
  end

  # MILLISECONDS, converted here so no unit maths happens on the far side of a
  # `data-` attribute.
  def test_the_interval_reaches_the_dom_in_milliseconds
    volatile = Class.new(Bali::Widget::ValueBase) do
      def self.key = "volatile"
      refresh_every 90.seconds
      value { 7 }
    end

    render_inline(Bali::Widget::Component.new(volatile.new, refresh_url: "/dashboard/refresh"))

    assert_selector "[data-bali-widget-refresh-interval-value='90000']"
  end

  # PRESENT ON EVERY REFRESHING CARD, and hidden from sight until the controller
  # says the card has stopped. A screen-reader user can find the age at any time;
  # a sighted one is told only when it starts to matter.
  def test_a_refreshing_card_carries_its_age_hidden
    render_inline(Bali::Widget::Component.new(volatile_widget.new, size: :medium,
                                              refresh_url: "/dashboard/refresh"))

    assert_selector ".bali-widget-freshness.sr-only", visible: :all
    assert_selector ".bali-widget-freshness time[datetime]", visible: :all
    assert_selector "[data-bali-widget-refresh-target='freshness']", visible: :all
  end

  # A card that never claimed to keep itself current has nothing to disclaim.
  def test_a_static_card_has_no_freshness_stamp
    render_inline(card(steady_widget.new))

    assert_no_selector ".bali-widget-freshness", visible: :all
  end

  # The hero flags itself, because the badge must never become visible there —
  # one fact and one tap target is the whole contract of a 215px tile.
  def test_the_hero_marks_its_stamp_as_never_visible
    render_inline(Bali::Widget::Component.new(volatile_widget.new, size: :small,
                                              refresh_url: "/dashboard/refresh"))

    assert_selector ".bali-widget-freshness[data-hero='true']", visible: :all
  end

  private


  def volatile_widget
    Class.new(Bali::Widget::ValueBase) do
      def self.key = "volatile"
      supports :small, :medium, :large
      refresh_every 30.seconds
      value { 7 }
    end
  end

  def steady_widget
    Class.new(Bali::Widget::ValueBase) do
      def self.key = "steady"
      value { 1 }
    end
  end
end
