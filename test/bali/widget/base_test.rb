# frozen_string_literal: true

require "test_helper"

class BaliWidgetBaseTest < ActiveSupport::TestCase
  class LowStockItems < Bali::Widget::Base
    sized :medium

    # Overridden so the test needs no locale files; the i18n readers are covered
    # separately below.
    def self.title = "Low stock items"
    def self.short_title = "Low stock"
    def self.empty_message = "Nothing running low"

    def call
      Bali::Widget::Result.new(count: 2, view_all_path: "/items",
                               items: [ Bali::Widget::Row.new(title: "Tomatoes") ])
    end
  end

  class Exploding < Bali::Widget::Base
    sized :small

    def self.title = "Exploding"

    def call = raise("boom")
  end

  class Hidden < Bali::Widget::Base
    sized :small

    def self.title = "Hidden"

    def visible? = false

    def call = Bali::Widget::Result.new
  end

  def test_key_is_derived_from_the_class_name
    assert_equal "low_stock_items", LowStockItems.key
  end

  def test_sized_rejects_an_unknown_size
    error = assert_raises(ArgumentError) do
      Class.new(Bali::Widget::Base) { sized :enormous }
    end

    assert_match(/unknown widget size/, error.message)
  end

  def test_the_result_carries_the_readers_rather_than_the_widget
    widget = LowStockItems.new

    assert_equal 2, widget.result.count
    assert_equal "/items", widget.result.view_all_path
    assert_equal [ "Tomatoes" ], widget.result.items.map(&:title)
    refute_predicate widget.result, :failed?
  end

  # ---- what a user may choose --------------------------------------------

  def test_every_size_is_offered_by_default
    assert_equal Bali::Widget::SIZES, LowStockItems.supported_sizes
  end

  # A bare count at `large` is a title, a number and most of a 2x2 cell of
  # whitespace. A widget with nothing to fill a canvas should not invite one.
  def test_a_widget_can_offer_a_subset
    klass = Class.new(Bali::Widget::Base) do
      sized :small
      supports :small, :medium
    end

    assert_equal %i[small medium], klass.supported_sizes
  end

  # DECLARED, not inferred: validated at class-definition time like `sized`, so a
  # typo is a boot failure rather than a picker that quietly offers nothing.
  def test_an_unknown_size_is_a_boot_failure
    assert_raises(ArgumentError) do
      Class.new(Bali::Widget::Base) { supports :small, :enormous }
    end
  end

  def test_offering_nothing_is_a_boot_failure
    assert_raises(ArgumentError) { Class.new(Bali::Widget::Base) { supports } }
  end

  # Otherwise the widget renders at a size its own picker cannot get back to.
  def test_the_default_must_be_one_a_user_can_choose
    error = assert_raises(ArgumentError) do
      Class.new(Bali::Widget::Base) do
        sized :large
        supports :small, :medium
      end
    end

    assert_match(/must be one a user can choose/, error.message)
  end

  # A stored row can name a size this widget stopped offering. Falling back beats
  # refusing to draw — the same call `with_size` already makes for a retired name.
  def test_a_stored_size_the_widget_no_longer_offers_falls_back_to_its_default
    klass = Class.new(Bali::Widget::Base) do
      sized :small
      supports :small, :medium
    end

    assert_equal :small, klass.new.with_size("large").size
    assert_equal :medium, klass.new.with_size("medium").size
  end

  def test_with_size_copies_rather_than_mutating_the_class
    resized = LowStockItems.new.with_size("large")

    assert_equal :large, resized.size
    assert_equal :medium, LowStockItems.new.size
    assert_equal :medium, LowStockItems.size
  end

  def test_with_size_falls_back_to_the_declared_size_for_a_retired_name
    assert_equal :medium, LowStockItems.new.with_size("enormous").size
    assert_equal :medium, LowStockItems.new.with_size(nil).size
  end

  def test_a_raising_call_becomes_a_failed_result_in_production
    swallowing_load_errors do
      widget = Exploding.new

      assert_predicate widget.result, :failed?
      assert_equal 0, widget.result.count
    end
  end

  def test_a_raising_call_is_memoized_so_the_query_runs_once
    calls = 0
    klass = Class.new(Bali::Widget::Base) do
      sized :small
      # Anonymous classes have no `name`, and `key` derives from it — so declare
      # one, the same way `test_i18n_readers_use_the_configured_scope` does.
      def self.key = "memoizing"
      define_method(:call) do
        calls += 1
        raise "boom"
      end
    end

    swallowing_load_errors do
      widget = klass.new
      widget.result.failed?
      widget.result.count
      widget.result.items
    end

    assert_equal 1, calls
  end

  def test_a_raising_call_still_raises_in_development_and_test
    assert_raises(RuntimeError) { Exploding.new.result }
  end

  def test_authorized_for_selects_on_visible
    widgets = [ LowStockItems.new, Hidden.new ]

    assert_equal [ LowStockItems ], Bali::Widget.authorized_for(widgets).map(&:class)
  end

  def test_i18n_readers_use_the_configured_scope
    klass = Class.new(Bali::Widget::Base) do
      sized :small
      def self.key = "demo"
      def call = Bali::Widget::Result.new
    end

    I18n.backend.store_translations(:en, widgets: { demo: { title: "Demo widget" } })

    assert_equal "Demo widget", klass.title
    # short_title falls back to title, so a widget only needs a short one if its
    # real one doesn't fit.
    assert_equal "Demo widget", klass.short_title
  end

  def test_raise_load_errors_is_true_in_development_and_test
    assert Bali::Widget.raise_load_errors?
  end

  def test_a_widget_that_forgets_call_degrades_instead_of_taking_the_page_down
    klass = Class.new(Bali::Widget::Base) do
      sized :small
      def self.key = "forgetful"
    end

    swallowing_load_errors do
      assert_predicate klass.new.result, :failed?
    end
  end

  def test_list_from_counts_the_whole_scope_but_previews_only_the_cap
    tenant = Tenant.create(name: "Test Studio")
    (Bali::Widget::Base::PREVIEW_ROWS + 3).times { |i| Movie.create!(name: "Movie #{i}", tenant_id: tenant.id) }

    klass = Class.new(Bali::Widget::Base) do
      sized :medium
      def self.key = "listing"
      def call = list_from(Movie.order(:name), view_all_path: "/movies")
      private def row(movie) = Bali::Widget::Row.new(title: movie.name)
    end

    result = klass.new.result

    # The count is the WHOLE scope; the preview is capped. That split is what
    # lets `#call` stay ignorant of the size it will be rendered at.
    assert_equal Bali::Widget::Base::PREVIEW_ROWS + 3, result.count
    assert_equal Bali::Widget::Base::PREVIEW_ROWS, result.items.size
    assert_equal "/movies", result.view_all_path
    assert_equal "Movie 0", result.items.first.title
  end

  private

  # `Bali::Widget.raise_load_errors?` is a method rather than a constant
  # precisely so a test can swap it. Minitest 6 extracted `Object#stub` into a
  # separate gem, and one test's syntax is not worth a dependency — so save the
  # original bound method and put it back, which is all `stub` did here anyway.
  def swallowing_load_errors
    original = Bali::Widget.method(:raise_load_errors?)
    Bali::Widget.define_singleton_method(:raise_load_errors?) { false }
    yield
  ensure
    Bali::Widget.define_singleton_method(:raise_load_errors?, original)
  end
end
