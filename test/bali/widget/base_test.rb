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

  def test_delegates_result_readers
    widget = LowStockItems.new

    assert_equal 2, widget.count
    assert_equal "/items", widget.view_all_path
    assert_equal [ "Tomatoes" ], widget.items.map(&:title)
    refute_predicate widget, :failed?
  end

  def test_with_size_copies_rather_than_mutating_the_class
    resized = LowStockItems.new.with_size("wide")

    assert_equal :wide, resized.size
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

      assert_predicate widget, :failed?
      assert_equal 0, widget.count
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
      widget.failed?
      widget.count
      widget.items
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
      assert_predicate klass.new, :failed?
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
