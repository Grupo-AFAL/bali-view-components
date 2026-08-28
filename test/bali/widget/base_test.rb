# frozen_string_literal: true

require "test_helper"

# What every widget is, whichever ladder it walks.
class BaliWidgetBaseTest < ActiveSupport::TestCase
  class Bare < Bali::Widget::Base
    def self.key = "bare"
  end

  def test_it_answers_every_question_the_card_asks_with_a_null
    widget = Bare.new

    assert_equal 0, widget.count
    assert_empty widget.items
    assert_nil widget.view_all_path
    assert_nil widget.trend
    assert_nil widget.series
    assert_nil widget.goal
    refute_predicate widget, :failed?
  end

  # THE POINT OF THE NULLS: the card reads one interface and never asks what kind
  # of widget it is holding. A `ValueBase` has no rows; the region that would
  # have shown them simply does not render.
  def test_a_pattern_overrides_only_what_it_has
    value = Class.new(Bali::Widget::ValueBase) { def self.key = "v"; value { 7 } }.new

    assert_equal 7, value.count
    assert_empty value.items
    assert_nil value.series
  end

  # ---- sizes ---------------------------------------------------------------

  def test_the_default_size_is_validated_at_class_definition_time
    assert_raises(ArgumentError) { Class.new(Bali::Widget::Base) { default_size :enormous } }
  end

  def test_every_size_is_offered_unless_a_widget_says_otherwise
    assert_equal Bali::Widget::SIZES, Bare.supported_sizes
  end

  def test_a_widget_can_offer_a_subset
    klass = Class.new(Bali::Widget::Base) { default_size :small; supports :small, :medium }

    assert_equal %i[small medium], klass.supported_sizes
  end

  # Otherwise the widget renders at a size its own picker cannot get back to.
  def test_the_default_must_be_one_a_user_can_choose
    error = assert_raises(ArgumentError) do
      Class.new(Bali::Widget::Base) { default_size :large; supports :small, :medium }
    end

    assert_match(/must be one a user can choose/, error.message)
  end

  def test_offering_nothing_is_refused
    assert_raises(ArgumentError) { Class.new(Bali::Widget::Base) { supports } }
  end

  # A stored row can name a size the widget stopped offering. Falling back beats
  # refusing to draw.
  def test_an_unsupported_stored_size_falls_back_to_the_default
    klass = Class.new(Bali::Widget::Base) do
      def self.key = "k"
      default_size :small
      supports :small, :medium
    end

    assert_equal :small, klass.new.with_size("large").size
    assert_equal :medium, klass.new.with_size("medium").size
  end

  # `_default_size` is a class attribute: assigning it would resize the widget
  # for every user in the process until the next deploy.
  def test_with_size_copies_rather_than_mutating_the_class
    resized = Bare.new.with_size(:large)

    assert_equal :large, resized.size
    assert_equal Bali::Widget::SIZES.first, Bare.new.size
  end

  # ---- copy ----------------------------------------------------------------

  # Read with no argument, set with one — so a widget with a single literal
  # string says it, and one with translations says nothing.
  def test_copy_can_be_a_literal_or_come_from_i18n
    literal = Class.new(Bali::Widget::Base) { def self.key = "lit"; title "Overdue tasks" }

    assert_equal "Overdue tasks", literal.title
    assert_match(/[Tt]ranslation missing/, Bare.title)
  end

  def test_short_title_falls_back_to_the_full_title
    klass = Class.new(Bali::Widget::Base) { def self.key = "st"; title "A very long title" }

    assert_equal "A very long title", klass.short_title
  end

  # ---- failure -------------------------------------------------------------

  # A tile that vanishes reads as "nothing to see", which is the one thing a
  # failure must not say — so a raising widget renders the degraded card.
  def test_a_raising_widget_degrades_rather_than_taking_the_page_down
    klass = Class.new(Bali::Widget::ValueBase) do
      def self.key = "boom"
      value { raise("upstream is down") }
    end
    widget = klass.new

    swallowing_load_errors do
      assert_equal 0, widget.count
      assert_predicate widget, :failed?
    end
  end

  # The card asks `count`, `items` and `view_all_path` separately; a rescue that
  # did not remember would re-run the raising query three times per tile.
  def test_the_failure_is_memoised
    calls = 0
    klass = Class.new(Bali::Widget::ValueBase) do
      def self.key = "boom2"
      define_method(:value) { calls += 1; raise "upstream is down" }
    end
    widget = klass.new

    swallowing_load_errors { 3.times { widget.count } }

    assert_equal 1, calls
  end

  # Loud where someone can fix it: a widget bug in development is a bug, not a
  # permanently apologetic tile. `raise_load_errors?` is true in the test env.
  def test_it_raises_in_development_rather_than_hiding_the_bug
    klass = Class.new(Bali::Widget::ValueBase) do
      def self.key = "boom3"
      value { raise("upstream is down") }
    end

    assert Bali::Widget.raise_load_errors?
    assert_raises(RuntimeError) { klass.new.count }
  end

  def test_visible_defaults_to_true_and_is_the_hosts_to_override
    assert_predicate Bare.new, :visible?
    hidden = Class.new(Bali::Widget::Base) { def visible? = false }.new

    assert_empty Bali::Widget.authorized_for([ hidden ])
  end

  private

  # `raise_load_errors?` is a method rather than a constant precisely so a test
  # can swap it. Minitest 6 extracted `Object#stub` into a separate gem, and one
  # test's syntax is not worth a dependency — so save the bound method and put it
  # back, which is all `stub` did here anyway.
  def swallowing_load_errors
    original = Bali::Widget.method(:raise_load_errors?)
    Bali::Widget.define_singleton_method(:raise_load_errors?) { false }
    yield
  ensure
    Bali::Widget.define_singleton_method(:raise_load_errors?, original)
  end
end
