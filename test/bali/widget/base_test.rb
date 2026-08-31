# frozen_string_literal: true

require "test_helper"

# What every widget is, whichever ladder it walks.
class BaliWidgetBaseTest < ActiveSupport::TestCase
  class Bare < Bali::Widget::Base
    def self.key = "bare"
  end

  # WHAT EVERY WIDGET HAS, and nothing more: where it links, who may see it, and
  # its copy. Everything a PATTERN answers — `count`, `display_value`, `items`,
  # `trend`, `series`, `goal`, `state` — belongs to the pattern that has it, and
  # the card defaults the rest. SIZE is not here either: it is a per-owner
  # arrangement fact, carried by `Bali::Widget::Placement`.
  def test_base_carries_only_what_every_widget_shares
    widget = Bare.new

    assert_nil widget.view_all_path
    assert_predicate widget, :authorized?
    assert_equal "bare", widget.key
  end

  # A WIDGET ANSWERS FOR WHAT IT IS, and rescues nothing. The pattern reads
  # belong to the pattern that has them; `failed?`, `load` and `safely` belong to
  # nobody — a widget RAISES, and `Bali::Widget::Component` is the error boundary
  # that catches it.
  def test_base_does_not_answer_for_patterns_it_is_not
    %i[items trend series goal state failed? load safely].each do |pattern_read|
      refute_respond_to Bare.new, pattern_read
    end
  end

  # THE THREE THE CARD ASKS EVERY WIDGET are declared here and implemented
  # nowhere — the contract stated once, since the card cannot ask what kind of
  # widget it is holding. `Base` cannot answer them because each means something
  # different per pattern.
  def test_base_declares_the_pattern_contract_without_answering_it
    %i[count any? display_value].each do |contract|
      assert_respond_to Bare.new, contract

      error = assert_raises(NotImplementedError) { Bare.new.public_send(contract) }
      assert_match(/must subclass one of/, error.message)
      assert_match(/ValueBase/, error.message, "the message must name the patterns")
    end
  end

  # Each pattern answers exactly its own.
  def test_a_pattern_answers_only_what_it_has
    value = Class.new(Bali::Widget::ValueBase) { def self.key = "v"; value { 7 } }.new

    assert_equal 7, value.count
    assert_equal "7", value.display_value
    refute_respond_to value, :items
    refute_respond_to value, :series
    assert_respond_to Class.new(Bali::Widget::ListBase) { def self.key = "l" }.new, :items
  end

  # A WIDGET THAT IS NONE OF THE FIVE FAILS BY NAME. THE PATTERN IS THE TYPE, so
  # subclassing `Base` directly is not a supported thing — and it used to fail as
  # a bare `NoMethodError` from inside the card, which told a host nothing.
  #
  # RENDERED, not merely constructed. The version of this test that only checked
  # which card class was chosen stayed green through a refactor that broke the
  # rendering outright, because the class is picked before anything is asked.
  def test_a_widget_that_is_no_pattern_at_all_fails_by_name
    counted = Class.new(Bali::Widget::Base) do
      def self.key = "counted"
      title "Counted"
      short_title "Counted"
      empty_message "-"
      def count = 3
    end.new

    error = assert_raises(NotImplementedError) do
      Bali::Widget::Card::Component.new(counted, size: :small).send(:display_value)
    end

    assert_match(/must subclass one of/, error.message)
  end

  # And each pattern reaches its own card, chosen from the widget's class rather
  # than from a registry the host has to keep in step.
  def test_each_pattern_reaches_its_own_card
    {
      Bali::Widget::ListBase => Bali::Widget::List::Component,
      Bali::Widget::TrendBase => Bali::Widget::Trend::Component,
      Bali::Widget::ProgressBase => Bali::Widget::Progress::Component,
      Bali::Widget::CheckBase => Bali::Widget::Check::Component,
      Bali::Widget::ValueBase => Bali::Widget::Value::Component
    }.each do |pattern, card|
      widget = Class.new(pattern) { def self.key = "w" }.new

      assert_kind_of card, Bali::Widget::Component.new(widget).send(:card)
    end
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
  # ON READ, not when either macro runs — see the next test for why.
  def test_the_default_must_be_one_a_user_can_choose
    klass = Class.new(Bali::Widget::Base) { default_size :large; supports :small, :medium }

    error = assert_raises(ArgumentError) { klass.default_size }

    assert_match(/must be one a user can choose/, error.message)
  end

  # AND A CATALOG TURNS THAT BACK INTO A BOOT FAILURE for every widget a host
  # actually put on a dashboard, since the macro runs after all class bodies.
  def test_a_catalog_refuses_a_widget_whose_default_it_does_not_offer
    klass = Class.new(Bali::Widget::ValueBase) do
      def self.name = "Broken"
      default_size :large
      supports :small, :medium
      value { 1 }
    end

    assert_raises(ArgumentError) { Bali::Widget.check_catalog!([ klass ]) }
  end

  # THE ORDER THE TWO MACROS APPEAR IN MUST NOT MATTER. Ruby reads a class body
  # top to bottom, and `ValueBase` ships `supports :small` — so a widget widening
  # it writes `default_size :medium` above `supports :small, :medium`, which the
  # old eager check rejected for a class that is perfectly valid.
  def test_default_size_may_be_declared_before_or_after_supports
    before = Class.new(Bali::Widget::ValueBase) do
      def self.key = "before"
      default_size :medium
      supports :small, :medium
      value { 1 }
    end
    after = Class.new(Bali::Widget::ValueBase) do
      def self.key = "after"
      supports :small, :medium
      default_size :medium
      value { 1 }
    end

    assert_equal :medium, before.default_size
    assert_equal :medium, after.default_size
  end

  # And one line does both.
  def test_supports_can_carry_the_default
    klass = Class.new(Bali::Widget::ValueBase) do
      def self.key = "one_line"
      supports :small, :medium, default: :medium
      value { 1 }
    end

    assert_equal :medium, klass.default_size
    assert_equal %i[small medium], klass.supported_sizes
  end

  def test_offering_nothing_is_refused
    assert_raises(ArgumentError) { Class.new(Bali::Widget::Base) { supports } }
  end

  # SIZE IS NOT A PROPERTY OF A WIDGET. It is a per-owner arrangement fact — the
  # same class is `small` for one person and `large` for another — so a widget
  # does not carry one, and `Bali::Widget::Placement` pairs the two.
  def test_a_widget_does_not_carry_a_size
    refute_respond_to Bare.new, :size
    refute_respond_to Bare.new, :with_size
    assert_equal Bali::Widget::SIZES.first, Bare.default_size
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

  # ---- keys ----------------------------------------------------------------

  # A key is the class name WITHOUT its namespace, so it is not unique by
  # construction. Silently keeping the last would drop a widget from the picker
  # AND render the survivor's data under the other's stored rows — a
  # data-integrity bug wearing a display bug's clothes.
  def test_two_classes_sharing_a_key_is_loud
    first = Class.new(Bali::Widget::ValueBase) { def self.name = "Reports::Overdue"; value { 1 } }
    second = Class.new(Bali::Widget::ValueBase) { def self.name = "Tasks::Overdue"; value { 2 } }

    error = assert_raises(Bali::Widget::DuplicateKey) do
      Bali::Widget.check_keys!([ first, second ])
    end

    assert_match(/share the key "overdue"/, error.message)
    assert_match(/Reports::Overdue, Tasks::Overdue/, error.message, "the message must name the classes")
    assert_match(/key "something_else"/, error.message, "and the fix")
  end

  # TWO DIFFERENT CLASSES, not the same one twice. A repeated key is an ordinary
  # submission — a picker can send one, and `Store#choose` dedupes it by design.
  def test_the_same_widget_twice_is_not_a_collision
    klass = Class.new(Bali::Widget::ValueBase) { def self.name = "Reports::Overdue"; value { 1 } }

    assert_equal [ "overdue" ], Bali::Widget.by_key([ klass.new, klass.new ]).keys
    Bali::Widget.check_keys!([ klass, klass ]) # must not raise
  end

  # The fix, and the reason a key is a declaration rather than only a derivation.
  def test_a_class_can_declare_its_own_key
    klass = Class.new(Bali::Widget::ValueBase) do
      def self.name = "Tasks::Overdue"
      key "tasks_overdue"
      value { 1 }
    end

    assert_equal "tasks_overdue", klass.key
    assert_equal "tasks_overdue", klass.new.key
  end

  # NOT namespace-qualified, deliberately: a qualified key would be
  # `constantize`-able, and a submitted key must become a widget only by being
  # found in the authorized offering.
  def test_a_derived_key_drops_the_namespace
    klass = Class.new(Bali::Widget::ValueBase) { def self.name = "Deeply::Nested::LowStockItems"; value { 1 } }

    assert_equal "low_stock_items", klass.key
  end

  # ---- authorization -------------------------------------------------------

  def test_authorized_defaults_to_true_and_is_the_hosts_to_override
    assert_predicate Bare.new, :authorized?
    hidden = Class.new(Bali::Widget::Base) { def authorized? = false }.new

    assert_empty Bali::Widget.authorized_for([ hidden ])
  end

  # ---- refresh_every -------------------------------------------------------

  # Reads with no argument, like every other declaration on `Base`. Without the
  # guard a reader call silently switches refreshing off.
  def test_refresh_every_reads_when_given_no_argument
    widget = Class.new(Bali::Widget::ValueBase) do
      def self.key = "volatile"
      refresh_every 30.seconds
      value { 1 }
    end

    assert_equal 30.0, widget.refresh_every
    assert_equal 30.0, widget.refresh_every, "reading must not clear it"
    assert_equal 30.0, widget.new.refresh_every
  end

  # OFF unless asked for. Most widgets answer a question that does not change
  # between page loads.
  def test_refresh_every_is_nil_by_default
    widget = Class.new(Bali::Widget::ValueBase) do
      def self.key = "steady"
      value { 1 }
    end

    assert_nil widget.refresh_every
  end

  # `0.5` for `5` is a plausible typo that turns one tile into a load generator,
  # so it fails at class-definition time rather than in production.
  def test_refresh_every_refuses_an_interval_below_the_floor
    error = assert_raises(ArgumentError) do
      Class.new(Bali::Widget::ValueBase) do
        def self.key = "greedy"
        refresh_every 0.5
        value { 1 }
      end
    end

    assert_match(/minimum is #{Bali::Widget::Base::MINIMUM_REFRESH}/, error.message)
  end

  # Inherited like every other declaration, and overridable.
  def test_refresh_every_is_inherited_and_overridable
    parent = Class.new(Bali::Widget::ValueBase) do
      def self.key = "parent_widget"
      refresh_every 60
      value { 1 }
    end
    child = Class.new(parent) do
      def self.key = "child_widget"
      refresh_every 10
    end

    assert_equal 60.0, parent.refresh_every, "the child must not write through to its parent"
    assert_equal 10.0, child.refresh_every
  end
end
