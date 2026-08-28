# frozen_string_literal: true

require "test_helper"
require "bali/testing/widget_catalog"

class BaliTestingWidgetCatalogTest < ActiveSupport::TestCase
  include Bali::Testing::WidgetCatalog

  # THE ASSERTION DOING ITS REAL JOB, against the dummy app's own widgets. Add a
  # file to `spec/dummy/app/widgets/` without listing it in the controller and
  # this fails — which is the whole point of shipping it.
  def test_every_dummy_widget_is_on_a_dashboard
    assert_every_widget_catalogued DashboardWidgetsController, path: "app/widgets"
  end

  # And it FAILS when something is missing, naming the class and what to do.
  def test_it_names_the_widget_you_forgot
    partial = DashboardWidgetsController.widget_catalog - [ DemoWidgets::RecentMovies ]

    error = assert_raises(Minitest::Assertion) do
      assert_every_widget_catalogued partial, path: "app/widgets"
    end

    assert_match "DemoWidgets::RecentMovies", error.message
    assert_match "dashboard_widgets catalog:", error.message
  end

  # A bare array works as well as a controller — a host that keeps its catalogs
  # somewhere Bali does not know about is not locked out.
  def test_a_plain_array_is_a_catalog
    assert_every_widget_catalogued DashboardWidgetsController.widget_catalog, path: "app/widgets"
  end

  # A LAZY CATALOG CANNOT BE READ HERE, and saying so is better than checking
  # against an empty list and passing.
  def test_a_lazy_catalog_says_it_cannot_be_checked
    lazy = Class.new(ActionController::Base) do
      define_singleton_method(:controller_path) { "lazy" }
      define_singleton_method(:name) { "LazyDashboardController" }
      include Bali::Concerns::Controllers::DashboardWidgets
      dashboard_widgets catalog: -> { [] }
    end

    error = assert_raises(ArgumentError) { assert_every_widget_catalogued lazy }

    assert_match "LazyDashboardController", error.message
    assert_match "resolved per request", error.message
  end

  # Anonymous widget classes defined by other tests must not be reported. This
  # one exists only to be swept up by a `Base.descendants` implementation.
  ANONYMOUS = Class.new(Bali::Widget::ValueBase) do
    def self.key = "never_catalogued"
    value { 1 }
  end

  def test_anonymous_test_widgets_are_not_reported
    assert_includes Bali::Widget::Base.descendants, ANONYMOUS
    assert_every_widget_catalogued DashboardWidgetsController, path: "app/widgets"
  end
end
