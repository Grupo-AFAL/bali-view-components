# frozen_string_literal: true

require "test_helper"

# THE PATTERN IS THE TYPE. Each base gives a widget its declarations and its
# abstract methods, and a widget picks exactly one.
class BaliWidgetPatternsTest < ActiveSupport::TestCase
  setup do
    @a = Studio.create!(name: "Alpha", country: "MX", status: :active, founded_year: 1990)
    @b = Studio.create!(name: "Beta", country: "US", status: :active, founded_year: 2000)
  end

  # ---- the declaration machinery -------------------------------------------

  # THE `dup`-ON-INHERIT RULE. `class_attribute` copies on WRITE and never on
  # MUTATION, so a subclass re-declaring would otherwise be handed its parent's
  # builder object and two siblings would overwrite each other's fields — last
  # class body loaded winning, which presents as "widget B shows widget A's
  # title" and depends on autoload order.
  def test_sibling_widgets_do_not_share_a_builder
    Studio.create!(name: "Shared", country: "MX")
    parent = Class.new(Bali::Widget::ListBase) do
      def self.key = "parent"
      list { Studio.where(name: "Shared") }
      row { |r| r.title :name }
    end
    first = Class.new(parent) { def self.key = "first"; row { |r| r.subtitle "FIRST" } }
    second = Class.new(parent) { def self.key = "second"; row { |r| r.subtitle "SECOND" } }

    assert_equal "FIRST", first.new.items.first.subtitle
    assert_equal "SECOND", second.new.items.first.subtitle
    # And the field neither of them re-declared still comes from the parent.
    assert_equal "Shared", first.new.items.first.title
  end

  def test_sibling_widgets_do_not_share_a_series_or_trend_builder
    parent = Class.new(Bali::Widget::TrendBase) do
      def self.key = "tparent"
      trend { |t| t.current 12; t.previous 6 }
      series { |s| s.labels %w[a b] }
    end
    up = Class.new(parent) { def self.key = "up"; trend { |t| t.positive_when :up } }
    down = Class.new(parent) { def self.key = "down"; trend { |t| t.positive_when :down } }
    one = Class.new(parent) { def self.key = "one"; series { |s| s.values [ 1, 2 ] } }
    two = Class.new(parent) { def self.key = "two"; series { |s| s.values [ 9, 9 ] } }

    assert_predicate up.new.trend, :good?
    refute_predicate down.new.trend, :good?
    assert_equal [ 1, 2 ], one.new.series.values
    assert_equal [ 9, 9 ], two.new.series.values
    assert_equal %w[a b], one.new.series.labels
  end

  # `:line` for a trend, `:bar` for a breakdown. Both patterns include the same
  # `Charted` module, so the default has to be per-including-class rather than
  # per-module — otherwise whichever loaded last would win for both.
  def test_the_series_default_type_does_not_leak_between_patterns
    trend = Class.new(Bali::Widget::TrendBase) do
      def self.key = "t"
      trend { |t| t.current 1; t.previous 1 }
      series { |s| s.values [ 1 ] }
    end
    progress = Class.new(Bali::Widget::ProgressBase) do
      def self.key = "p"
      goal { |g| g.value 1 }
      series { |s| s.values [ 1 ] }
    end

    assert_equal :line, trend.new.series.type
    assert_equal :bar, progress.new.series.type
  end

  # NINE of the fourteen hand-written errors were untested. They replace the
  # `NotImplementedError` and `ArgumentError` Ruby used to give for free, so
  # they are only a fair trade if they are as reliable — and the message IS the
  # documentation, so a message suggesting a declaration that then fails is a
  # bug in the API rather than in the prose.
  def test_every_declaration_says_what_it_needs_when_given_no_block
    {
      Bali::Widget::ListBase => %i[list row],
      Bali::Widget::TrendBase => %i[trend series],
      Bali::Widget::ProgressBase => %i[goal series]
    }.each do |base, macros|
      macros.each do |macro|
        error = assert_raises(ArgumentError, "#{base}.#{macro}") { Class.new(base).public_send(macro) }

        assert_match(/`#{macro}` needs a block/, error.message)
      end
    end

    error = assert_raises(ArgumentError) { Class.new(Bali::Widget::ValueBase).value }

    assert_match(/`value` needs a figure/, error.message)
  end

  # A list widget has no chart, so it is not `Charted` — asserting the absence
  # keeps the pattern boundary from quietly widening.
  def test_only_the_charted_patterns_offer_a_series
    assert_respond_to Bali::Widget::TrendBase, :series
    assert_respond_to Bali::Widget::ProgressBase, :series
    refute_respond_to Bali::Widget::ListBase, :series
    refute_respond_to Bali::Widget::ValueBase, :series
  end

  # The suggestion in each message has to be a declaration that WORKS. Two of
  # them used to suggest one that raised the next guard: `trend { |t|
  # t.positive_when :down }` has no `t.current`, and `goal { |g| g.label "of
  # 10" }` has no `g.value`.
  def test_the_suggested_declaration_in_each_message_actually_works
    trend = assert_raises(ArgumentError) { Class.new(Bali::Widget::TrendBase).trend }
    assert_match(/t\.current/, trend.message)

    goal = assert_raises(ArgumentError) { Class.new(Bali::Widget::ProgressBase).goal }
    assert_match(/g\.value/, goal.message)

    # And following them leaves a widget that loads.
    widget = Class.new(Bali::Widget::TrendBase) do
      def self.key = "suggested"
      trend { |t| t.current { 12 } }
    end.new

    assert_equal 12, widget.count
    assert_nil widget.trend, "no previous period means no trend, not a raise"
  end

  def test_a_trend_without_a_current_says_which_field_is_missing
    klass = Class.new(Bali::Widget::TrendBase) do
      def self.key = "nocurrent"
      trend { |t| t.period_label "vs last week" }
    end

    error = assert_raises(NotImplementedError) { klass.new.trend }

    assert_match(/must declare `t\.current`/, error.message)
  end

  def test_a_goal_without_a_value_says_which_field_is_missing
    klass = Class.new(Bali::Widget::ProgressBase) do
      def self.key = "novalue"
      goal { |g| g.label "of 10" }
    end

    error = assert_raises(NotImplementedError) { klass.new.goal }

    assert_match(/must declare `g\.value`/, error.message)
  end

  def test_a_pattern_without_its_declaration_at_all_says_so
    assert_match(/must declare `trend`/,
                 assert_raises(NotImplementedError) { Class.new(Bali::Widget::TrendBase) { def self.key = "x" }.new.trend }.message)
    assert_match(/must declare `goal`/,
                 assert_raises(NotImplementedError) { Class.new(Bali::Widget::ProgressBase) { def self.key = "y" }.new.goal }.message)
  end

  # `s.type` passed straight through to Chart.js unvalidated, so a typo emitted
  # `chart-type-value="banana"` — a canvas Chart.js cannot draw, a blank tile,
  # and an error only in the browser console. `default_size` and `supports`
  # already make the boot-failure bargain; this one did not.
  def test_an_unknown_series_type_is_a_boot_failure
    error = assert_raises(ArgumentError) do
      Class.new(Bali::Widget::TrendBase) { series { |s| s.type :banana } }
    end

    assert_match(/unknown series type :banana/, error.message)
    assert_match(/line or bar/, error.message, "the message should name the options")
  end

  # The two that survive the size ladder: both have axes for the sparkline to
  # strip below `large`, and both still read at a 2x1.
  def test_both_offered_series_types_are_accepted
    Bali::Widget::Charted::TYPES.each do |type|
      klass = Class.new(Bali::Widget::TrendBase) do
        def self.key = "typed"
        trend { |t| t.current 5; t.previous 3 }
        series { |s| s.values [ 1, 2 ]; s.type type }
      end

      assert_equal type, klass.new.series.type
    end
  end

  # ---- ValueBase -----------------------------------------------------------

  def value_widget(&block) = Class.new(Bali::Widget::ValueBase) { def self.key = "v" }.tap { it.class_eval(&block) }.new

  # A bare figure at `large` is a title, a number and most of a 2x2 cell of
  # whitespace — so one offered size is the class's default rather than a
  # limitation of it.
  def test_a_value_widget_offers_only_small_by_default
    assert_equal [ :small ], Bali::Widget::ValueBase.supported_sizes
  end

  def test_the_value_is_the_count_the_card_reads
    widget = value_widget { value { 42 } }

    assert_equal 42, widget.count
    assert_equal "42", widget.display_value
  end

  def test_a_value_widget_can_print_something_other_than_its_number
    widget = value_widget do
      value { 2_062_000_000 }
      display_value { "$#{Bali::Widget.abbreviate(value)}" }
    end

    assert_equal "$2.1B", widget.display_value
  end

  def test_forgetting_value_says_which_declaration_is_missing
    error = assert_raises(NotImplementedError) { value_widget { }.count }

    assert_match(/must declare `value`/, error.message)
  end

  # ---- ListBase ------------------------------------------------------------

  def list_widget(&block) = Class.new(Bali::Widget::ListBase) { def self.key = "l" }.tap { it.class_eval(&block) }.new

  # A list widget owes a `row` the way it owes a `list`. Without one there is
  # nothing to build a row from, and `items` would otherwise fail deep inside
  # the builder with a nil receiver.
  def test_a_list_without_a_row_says_so
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "unrowed"
      list { Studio.all }
    end

    error = assert_raises(NotImplementedError) { klass.new.items }

    assert_match(/must declare `row`/, error.message)
  end

  # And a `row` that declares no title is the same class of mistake one level
  # in: every row renders blank, which reads as a data problem rather than an
  # unfinished widget. Checked once per render, not once per row.
  def test_a_row_without_a_title_says_so
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "untitled"
      list { Studio.all }
      row { |r| r.subtitle :country }
    end

    error = assert_raises(NotImplementedError) { klass.new.items }

    assert_match(/must declare `r.title`/, error.message)
  end

  # `title "Low stock items"` sits a few lines from `r.subtitle` in a real class
  # body, and every other builder reads a non-Proc as a literal. A string that
  # meant "send this to the record" made one field in the set disagree with the
  # rest, and failed as a `NoMethodError` on a method named "In stock".
  def test_a_string_row_field_is_the_value_rather_than_a_method_name
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "literal"
      row do |r|
        r.title :name
        r.subtitle "In stock"
      end
      list { Studio.where(name: "Flour") }
    end

    Studio.create!(name: "Flour")
    row = klass.new.items.first

    assert_equal "Flour", row.title
    assert_equal "In stock", row.subtitle
  end

  def test_a_list_answers_count_and_a_capped_preview_from_one_scope
    widget = list_widget do
      list { Studio.order(:name) }
      row do |r|
        r.title :name
      end
    end

    assert_equal Studio.count, widget.count
    assert_equal %w[Alpha Beta], widget.items.first(2).map(&:title)
  end

  # A Symbol is sent to the record; a block runs against the WIDGET with the
  # record yielded, so it can reach route helpers and private methods.
  def test_row_fields_take_a_symbol_or_a_block
    widget = list_widget do
      list { Studio.order(:name) }
      row do |r|
        r.title :name
        r.subtitle { |studio| join(studio.country, "studio") }
        r.href { |studio| "/studios/#{studio.id}" }
      end
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
      row do |r|
        r.title :name
      end
      list { Studio.order(name: :desc) }
    end

    assert_equal "Zed 8", widget.items.first.title
    assert_equal Bali::Widget::ListBase::PREVIEW_ROWS, widget.items.size
  end

  def test_a_list_without_a_scope_says_so
    error = assert_raises(NotImplementedError) { list_widget { row { |r| r.title :name } }.count }

    assert_match(/must declare `list`/, error.message)
  end

  # All three row fields take the same three forms. `row_href` used to be the
  # exception — block only — so `row_href :url` raised `wrong number of
  # arguments (given 1, expected 0)`, which names nothing about the API, and a
  # fixed path had to be written as a block returning a constant.
  def test_every_row_field_takes_a_symbol_a_block_or_a_string
    Studio.create!(name: "Flour", country: "MX")
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "forms"
      list { Studio.where(name: "Flour") }
      row do |r|
        r.title :name                              # sent to the record
        r.subtitle "In stock"                      # the value itself
        r.href { |studio| "/studios/#{studio.id}" } # run on the widget
      end
    end

    row = klass.new.items.first

    assert_equal "Flour", row.title
    assert_equal "In stock", row.subtitle
    assert_match(%r{\A/studios/\d+\z}, row.href)
  end

  def test_a_symbol_href_is_read_off_the_record_like_any_other_field
    Studio.create!(name: "Flour", country: "MX")
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "symhref"
      list { Studio.where(name: "Flour") }
      row do |r|
        r.title :name
        r.href :country
      end
    end

    assert_equal "MX", klass.new.items.first.href
  end

  # `count` and `previewable` both need the relation, and a block that does real
  # work before returning one should not do it twice. The RELATION is memoised,
  # never the rows — the two callers issue different queries off it, which is
  # what lets a card say "3 of 214".
  def test_the_scope_block_runs_once_per_render_but_still_issues_both_queries
    builds = 0
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "once"
      row do |r|
        r.title :name
      end
    end
    klass.list { builds += 1; Studio.where("name LIKE 'Once %'") }

    9.times { |i| Studio.create!(name: "Once #{i}", country: "US") }
    widget = klass.new

    assert_equal 9, widget.count
    assert_equal Bali::Widget::ListBase::PREVIEW_ROWS, widget.items.size
    assert_equal 1, builds
  end

  # A CLASS-level invariant, so it is checked once per render rather than once
  # per row — and reported for the widget, not for a record.
  def test_the_missing_row_title_is_checked_before_the_row_loop_not_inside_it
    3.times { |i| Studio.create!(name: "Untitled #{i}", country: "US") }
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "untitled2"
      list { Studio.where("name LIKE 'Untitled %'") }
    end

    # Counting raises cannot tell "checked once up front" from "checked on the
    # first row and short-circuited" — both raise once. Counting how many RECORDS
    # the row builder saw can: a guard inside the loop would have touched one.
    seen = 0
    klass.class_eval { define_method(:row_for) { |record| seen += 1; super(record) } }

    assert_raises(NotImplementedError) { klass.new.items }
    assert_equal 0, seen, "the guard ran inside the row loop, not before it"
  end

  # Each setter writes its OWN attribute, so two `row` blocks merge field by
  # field rather than the second replacing the first. That is what lets a shared
  # module declare what two widgets have in common while each widget declares
  # only what differs. A declaration stored whole would have forced that module
  # to declare all three fields and call back into a method each widget had to
  # remember to define — an unenforced contract failing inside `safely`.
  def test_two_row_blocks_merge_field_by_field
    Studio.create!(name: "Flour", country: "MX")
    shared = Module.new do
      def self.included(base)
        base.row do |r|
          r.title :name
          r.href "/shared"
        end
      end
    end
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "merged"
      include shared
      list { Studio.where(name: "Flour") }
      row { |r| r.subtitle :country }
    end

    row = klass.new.items.first

    assert_equal "Flour", row.title    # from the module
    assert_equal "/shared", row.href   # from the module
    assert_equal "MX", row.subtitle    # from the widget
  end

  def test_row_without_a_block_says_so
    error = assert_raises(ArgumentError) { Class.new(Bali::Widget::ListBase) { row } }

    assert_match(/needs a block/, error.message)
  end

  # THE BUG THE BLOCK EXISTS TO PREVENT, stated as a date rather than a counter.
  # A class body runs once at boot, so a relation built there closes over the day
  # the process started — `due_date: Date.current..` silently keeps yesterday's
  # window and the tile shows the wrong week until a redeploy. The reloader
  # re-runs the class body on every request, so this cannot reproduce in
  # development: a production-only, silent failure, which is why `list` takes a
  # block and nothing else.
  def test_a_dated_scope_moves_with_the_clock
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "dated"
      row do |r|
        r.title :name
      end
      list { Studio.where(created_at: Date.current.all_day) }
    end

    travel_to(Time.zone.parse("2026-01-01 09:00")) { Studio.create!(name: "Today") }

    travel_to(Time.zone.parse("2026-01-01 12:00")) { assert_equal 1, klass.new.count }
    travel_to(Time.zone.parse("2026-01-02 12:00")) { assert_equal 0, klass.new.count }
  end

  # The same property counted rather than dated: the block is re-read per render,
  # which is what makes the dated case above work.
  def test_a_block_scope_is_re_read_on_every_render
    reads = 0
    klass = Class.new(Bali::Widget::ListBase) do
      def self.key = "lazy"
      row do |r|
        r.title :name
      end
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
    widget = trend_widget { trend { |t| t.current 12; t.previous 36 } }

    assert_equal(-67, widget.trend.delta)
    assert_equal :down, widget.trend.direction
    assert_equal 12, widget.count
  end

  # THE FIELD THE PATTERN EXISTS FOR. Overdue tasks up 12% and revenue up 12%
  # are opposite news; the card colours from `good?`, never `direction`.
  def test_positive_when_decides_whether_a_movement_is_good_news
    rising = ->(direction) { trend_widget { trend { |t| t.positive_when direction; t.current 12; t.previous 6 } } }

    assert_predicate rising.call(:up).trend, :good?
    refute_predicate rising.call(:down).trend, :good?
  end

  # A widget's first week has no previous period, and the trend is then ABSENT
  # rather than zero.
  def test_no_previous_period_means_no_trend
    assert_nil trend_widget { trend { |t| t.current 5 } }.trend
    assert_nil trend_widget { trend { |t| t.current 5; t.previous 0 } }.trend
  end

  def test_a_trend_widget_charts_its_history
    widget = trend_widget do
      series do |s|
        s.labels { %w[a b] }
        s.values { [ 3, 5 ] }
      end
      trend { |t| t.current 5; t.previous 3 }
    end

    assert_equal [ 3, 5 ], widget.series.values
    assert_equal :line, widget.series.type
  end

  def test_a_trend_widget_without_a_series_has_none
    assert_nil trend_widget { trend { |t| t.current 5; t.previous 3 } }.series
  end

  # ---- ProgressBase --------------------------------------------------------

  def progress_widget(&block) = Class.new(Bali::Widget::ProgressBase) { def self.key = "p" }.tap { it.class_eval(&block) }.new

  def test_a_progress_widget_answers_a_goal
    widget = progress_widget do
      goal { |g| g.label { "of #{max}" } }
      goal { |g| g.value 3; g.max 12 }
    end

    assert_equal 3, widget.goal.value
    assert_equal 12, widget.goal.max
    assert_equal "of 12", widget.goal.label
    assert_in_delta 25.0, widget.goal.percentage
  end

  # A ring has nowhere to draw the eleventh of ten, but "11 / 10" is a real and
  # good state — so only the drawing is clamped.
  def test_the_percentage_clamps_without_touching_the_value
    widget = progress_widget { goal { |g| g.value 11; g.max 10 } }

    assert_in_delta 100.0, widget.goal.percentage
    assert_equal 11, widget.goal.value
  end

  # "No goal set" is a configuration state, not an error.
  def test_a_zero_max_reads_as_empty_rather_than_dividing_by_zero
    widget = progress_widget { goal { |g| g.value 5; g.max 0 } }

    assert_in_delta 0.0, widget.goal.percentage
  end

  def test_a_progress_widget_charts_in_bars_by_default
    widget = progress_widget do
      series { |s| s.values { [ 3, 4 ] } }
      goal { |g| g.value 2; g.max 10 }
    end

    assert_equal :bar, widget.series.type
  end

  # ---- CheckBase -----------------------------------------------------------

  def check_widget(&block) = Class.new(Bali::Widget::CheckBase) { def self.key = "c" }.tap { it.class_eval(&block) }.new

  # TERNARY, NOT BOOLEAN. `nil` is "not checked yet" — a different statement from
  # a failing check, and the distinction `Bali::BooleanIcon` already draws.
  def test_a_check_answers_true_false_or_not_yet_known
    assert_equal true, check_widget { check { |c| c.value true } }.passing?
    assert_equal false, check_widget { check { |c| c.value false } }.passing?
    assert_nil check_widget { check { |c| c.value nil } }.passing?
  end

  # A truthy non-boolean reads as true rather than leaking through as itself,
  # which is what lets `c.value { record }` work.
  def test_a_truthy_answer_collapses_to_true
    assert_equal true, check_widget { check { |c| c.value "yes" } }.passing?
  end

  # A FAILING CHECK IS NOT AN EMPTY ONE. `count.positive?` drives the card's
  # muted "nothing here" treatment and its "view all" link, so `false` has to
  # count as an answer — only `nil` is genuinely nothing.
  def test_a_failing_check_still_counts_as_an_answer
    assert_equal 1, check_widget { check { |c| c.value true } }.count
    assert_equal 1, check_widget { check { |c| c.value false } }.count
    assert_equal 0, check_widget { check { |c| c.value nil } }.count
  end

  def test_the_labels_default_to_balis_own_wording
    assert_equal I18n.t("bali_view.widgets.check.pass"),
                 check_widget { check { |c| c.value true } }.display_value
    assert_equal I18n.t("bali_view.widgets.check.fail"),
                 check_widget { check { |c| c.value false } }.display_value
  end

  def test_the_labels_run_against_the_widget_so_they_can_read_its_data
    widget = check_widget do
      check do |c|
        c.value { false }
        c.fail { "#{blockers} blocking" }
      end
      define_method(:blockers) { 4 }
    end

    assert_equal "4 blocking", widget.display_value
  end

  # A check is one fact, so there is nothing to fill a 2x2 — `ValueBase`'s reason.
  def test_a_check_offers_only_small_by_default
    assert_equal [ :small ], Bali::Widget::CheckBase.supported_sizes
  end

  def test_a_check_without_a_value_says_so
    error = assert_raises(NotImplementedError) { check_widget { check { |c| c.pass "OK" } }.count }

    assert_match(/must declare `c\.value`/, error.message)
  end

  def test_a_check_without_a_check_block_says_so
    error = assert_raises(NotImplementedError) { check_widget { }.count }

    assert_match(/must declare `check`/, error.message)
  end

  def test_two_check_blocks_merge_field_by_field
    parent = Class.new(Bali::Widget::CheckBase) do
      def self.key = "cparent"
      check { |c| c.value true; c.pass "SHARED" }
    end
    child = Class.new(parent) { def self.key = "cchild"; check { |c| c.value false } }

    assert_equal false, child.new.passing?
    assert_equal "SHARED", parent.new.display_value
  end

  # ---- the missing-declaration message ------------------------------------

  # THE ONE THING THE DELETED `Builder` BASE CLASS WAS ACTUALLY PROTECTING.
  # `check!` used to be inherited, so all four patterns raised in one voice by
  # construction. They each own the method now — which reads better and killed a
  # fragile derivation of an ivar name from the message string — so the shape is
  # pinned here instead. This is the property; inheritance was only ever one way
  # of holding it.
  #
  # NAMES THE WIDGET, THE DECLARATION AND THE BLOCK. A host who reads
  # "must declare `t.current` in its `trend` block" can act without opening Bali;
  # "undefined method" cannot be acted on at all.
  MISSING_DECLARATIONS = {
    Bali::Widget::ListBase => [ "r.title", "row" ],
    Bali::Widget::TrendBase => [ "t.current", "trend" ],
    Bali::Widget::ProgressBase => [ "g.value", "goal" ],
    Bali::Widget::CheckBase => [ "c.value", "check" ]
  }.freeze

  def test_every_pattern_names_the_declaration_it_is_missing
    MISSING_DECLARATIONS.each do |pattern, (declaration, block)|
      widget = Class.new(pattern) do
        def self.name = "Forgetful"
        # the block is declared, but the required field inside it is not
        public_send(block) { |_| }
      end.new

      error = assert_raises(NotImplementedError, "#{pattern} did not raise") { widget.count }

      assert_equal "Forgetful must declare `#{declaration}` in its `#{block}` block.",
                   error.message
    end
  end

  # An anonymous class says something rather than "must declare `x` for nil".
  def test_the_message_survives_a_widget_with_no_name
    widget = Class.new(Bali::Widget::TrendBase) { trend { |_| } }.new

    error = assert_raises(NotImplementedError) { widget.count }

    assert_equal "This widget must declare `t.current` in its `trend` block.", error.message
  end

  # `c.value false` IS a declaration — the sentinel is what distinguishes it from
  # never declaring, and inlining `check!` is where that could most easily have
  # been lost.
  def test_a_check_declaring_false_is_not_a_missing_declaration
    widget = Class.new(Bali::Widget::CheckBase) do
      def self.key = "declared_false"
      check { |c| c.value false }
    end.new

    assert_equal false, widget.passing?
  end
end
