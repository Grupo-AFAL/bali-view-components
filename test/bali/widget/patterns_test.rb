# frozen_string_literal: true

require "test_helper"

# THE PATTERN IS THE TYPE. Each base gives a widget its declarations and its
# abstract methods, and a widget picks exactly one.
class BaliWidgetPatternsTest < ActiveSupport::TestCase
  setup do
    @a = Studio.create!(name: "Alpha", country: "MX", status: :active, founded_year: 1990)
    @b = Studio.create!(name: "Beta", country: "US", status: :active, founded_year: 2000)
  end

  # ---- ValueBase -----------------------------------------------------------

  def value_widget(&block) = Class.new(Bali::Widget::ValueBase) { def self.key = "v" }.tap { it.class_eval(&block) }.new

  # A bare figure at `large` is a title, a number and most of a 2x2 cell of
  # whitespace — so this is the class's default rather than a limitation of it.
  # `title "Low stock items"` sits three lines from `row_subtitle` in a real
  # class body, and `ProgressBase#goal_label` already reads a non-Proc as the
  # value. A string that meant "send this to the record" made one macro in the
  # set disagree with the rest, and failed as a `NoMethodError` on a method
  # named "In stock".
  # The counterpart to a missing `#scope`. A list widget with no `row_title`
  # used to render a column of blank rows, which reads as a data problem rather
  # than an unfinished widget.
  def test_a_list_without_a_row_title_says_so
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "untitled"
      list { Studio.all }
    end

    error = assert_raises(NotImplementedError) { klass.new.items }

    assert_match(/row_title/, error.message)
  end

  def test_a_string_row_field_is_the_value_rather_than_a_method_name
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "literal"
      row_title :name
      row_subtitle "In stock"
      list { Studio.where(name: "Flour") }
    end

    Studio.create!(name: "Flour")
    row = klass.new.items.first

    assert_equal "Flour", row.title
    assert_equal "In stock", row.subtitle
  end

  def test_a_value_widget_offers_only_small_by_default
    assert_equal [ :small ], Bali::Widget::ValueBase.supported_sizes
  end

  def test_the_value_is_the_count_the_card_reads
    widget = value_widget { def value = 42 }

    assert_equal 42, widget.count
    assert_equal "42", widget.display_value
  end

  def test_a_value_widget_can_print_something_other_than_its_number
    widget = value_widget do
      def value = 2_062_000_000
      def formatted_value = "$#{Bali::Widget.abbreviate(value)}"
    end

    assert_equal "$2.1B", widget.display_value
  end

  def test_forgetting_value_says_which_method_is_missing
    error = assert_raises(NotImplementedError) { value_widget { }.count }

    assert_match(/must define `#value`/, error.message)
  end

  # ---- ListBase ------------------------------------------------------------

  def list_widget(&block) = Class.new(Bali::Widget::ListBase) { def self.key = "l" }.tap { it.class_eval(&block) }.new

  def test_a_list_answers_count_and_a_capped_preview_from_one_scope
    widget = list_widget do
      list { Studio.order(:name) }
      row_title :name
    end

    assert_equal Studio.count, widget.count
    assert_equal %w[Alpha Beta], widget.items.first(2).map(&:title)
  end

  # A Symbol is sent to the record; a block runs against the WIDGET with the
  # record yielded, so it can reach route helpers and private methods.
  def test_row_fields_take_a_symbol_or_a_block
    widget = list_widget do
      list { Studio.order(:name) }
      row_title :name
      row_subtitle { |studio| subtitle(studio.country, "studio") }
      row_href { |studio| "/studios/#{studio.id}" }
    end
    row = widget.items.first

    assert_equal "Alpha", row.title
    assert_equal "MX · studio", row.subtitle
    assert_equal "/studios/#{@a.id}", row.href
  end

  # ORDER THEN LIMIT. The reverse reads the first rows the database happens to
  # return and sorts those.
  def test_the_order_is_applied_before_the_preview_is_taken
    9.times { |i| Studio.create!(name: "Zed #{i}", country: "US", status: :active) }
    widget = list_widget do
      row_title :name
      list { Studio.order(name: :desc) }
    end

    assert_equal "Zed 8", widget.items.first.title
    assert_equal Bali::Widget::Base::PREVIEW_ROWS, widget.items.size
  end

  def test_a_list_without_a_scope_says_so
    error = assert_raises(NotImplementedError) { list_widget { row_title :name }.count }

    assert_match(/must declare `list`/, error.message)
  end

  # A class body runs once at boot, so a relation passed by value freezes
  # whatever it closed over then — `Date.current` is the day the process
  # started. The block form is re-read per render, which is why it is the one
  # the docs lead with.
  # THE BUG THE BLOCK EXISTS TO PREVENT, stated as a date rather than a counter.
  # A class body runs once at boot, so a relation built there closes over the
  # day the process started — `due_date: Date.current..` silently keeps
  # yesterday's window and the tile shows the wrong week until a redeploy. The
  # reloader re-runs the class body on every request, so this cannot reproduce
  # in development: it is a production-only, silent failure, which is why `list`
  # takes a block and nothing else.
  def test_a_dated_scope_moves_with_the_clock
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "dated"
      row_title :name
      list { Studio.where(created_at: Date.current.all_day) }
    end

    travel_to(Time.zone.parse("2026-01-01 09:00")) { Studio.create!(name: "Today") }

    travel_to(Time.zone.parse("2026-01-01 12:00")) { assert_equal 1, klass.new.count }
    travel_to(Time.zone.parse("2026-01-02 12:00")) { assert_equal 0, klass.new.count }
  end

  def test_a_block_scope_is_re_read_on_every_render
    reads = 0
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "lazy"
      row_title :name
    end
    # Counted INSIDE the declaration, which is the thing under test. Counting it
    # in a `define_method(:scope)` would override the resolution this asserts,
    # and would pass just as happily against a relation frozen at boot.
    klass.list { reads += 1; Studio.all }

    2.times { klass.new.count }

    assert_equal 2, reads
  end

  # ---- TrendBase -----------------------------------------------------------

  def trend_widget(&block) = Class.new(Bali::Widget::TrendBase) { def self.key = "t" }.tap { it.class_eval(&block) }.new

  # The base computes the delta — every trend widget was hand-rolling it.
  def test_the_base_computes_the_delta_from_current_and_previous
    widget = trend_widget { def current = 12; def previous = 36 }

    assert_equal(-67, widget.trend.delta)
    assert_equal :down, widget.trend.direction
    assert_equal 12, widget.count
  end

  # THE FIELD THE PATTERN EXISTS FOR. Overdue tasks up 12% and revenue up 12%
  # are opposite news; the card colours from `good?`, never `direction`.
  def test_positive_when_decides_whether_a_movement_is_good_news
    rising = ->(direction) { trend_widget { positive_when direction; def current = 12; def previous = 6 } }

    assert_predicate rising.call(:up).trend, :good?
    refute_predicate rising.call(:down).trend, :good?
  end

  # A widget's first week has no previous period, and the trend is then ABSENT
  # rather than zero.
  def test_no_previous_period_means_no_trend
    assert_nil trend_widget { def current = 5; def previous = nil }.trend
    assert_nil trend_widget { def current = 5; def previous = 0 }.trend
  end

  def test_a_trend_widget_charts_its_history
    widget = trend_widget do
      series_labels { %w[a b] }
      series_values { [ 3, 5 ] }
      def current = 5
      def previous = 3
    end

    assert_equal [ 3, 5 ], widget.series.values
    assert_equal :line, widget.series.type
  end

  def test_a_trend_widget_without_a_series_has_none
    assert_nil trend_widget { def current = 5; def previous = 3 }.series
  end

  # ---- ProgressBase --------------------------------------------------------

  def progress_widget(&block) = Class.new(Bali::Widget::ProgressBase) { def self.key = "p" }.tap { it.class_eval(&block) }.new

  def test_a_progress_widget_answers_a_goal
    widget = progress_widget do
      goal_label { "of #{max}" }
      def value = 3
      def max = 12
    end

    assert_equal 3, widget.goal.value
    assert_equal 12, widget.goal.max
    assert_equal "of 12", widget.goal.label
    assert_in_delta 25.0, widget.goal.percentage
  end

  # A ring has nowhere to draw the eleventh of ten, but "11 / 10" is a real and
  # good state — so only the drawing is clamped.
  def test_the_percentage_clamps_without_touching_the_value
    widget = progress_widget { def value = 11; def max = 10 }

    assert_in_delta 100.0, widget.goal.percentage
    assert_equal 11, widget.goal.value
  end

  # "No goal set" is a configuration state, not an error.
  def test_a_zero_max_reads_as_empty_rather_than_dividing_by_zero
    widget = progress_widget { def value = 5; def max = 0 }

    assert_in_delta 0.0, widget.goal.percentage
  end

  def test_a_progress_widget_charts_in_bars_by_default
    widget = progress_widget do
      series_values { [ 3, 4 ] }
      def value = 2
      def max = 10
    end

    assert_equal :bar, widget.series.type
  end
end
