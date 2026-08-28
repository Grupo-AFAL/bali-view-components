# frozen_string_literal: true

require "test_helper"

# The concern's CONFIGURATION and SEAMS. What it does over HTTP — the six
# actions, the params filters, the picker template — is covered end to end by
# `test/requests/dashboard_widgets_test.rb` against the dummy's real controller.
# This covers the parts a host gets wrong before it ever serves a request.
class BaliDashboardWidgetsConcernTest < ActiveSupport::TestCase
  ALPHA = Class.new(Bali::Widget::ValueBase) do
    def self.key = "alpha"
    value { 1 }
  end

  HIDDEN = Class.new(Bali::Widget::ValueBase) do
    def self.key = "hidden"
    value { 2 }
    def authorized? = false
  end

  # A bare controller class, because none of this needs a request.
  def controller_class(catalog: [ ALPHA ], dashboard_key: nil, path: "dashboards")
    Class.new(ActionController::Base) do
      define_singleton_method(:controller_path) { path }
      define_singleton_method(:name) { "AnonymousDashboardsController" }

      include Bali::Concerns::Controllers::DashboardWidgets

      dashboard_widgets catalog: catalog, dashboard_key: dashboard_key
    end
  end

  # THE ONE REQUIRED SEAM, and it fails with the controller's own name rather
  # than a bare NoMethodError from somewhere inside the Store — the contract the
  # class comment describes, enforced in code. Same shape as `Crudable`.
  def test_a_controller_that_forgets_widget_owner_says_so_by_name
    error = assert_raises(NotImplementedError) { controller_class.new.send(:widget_owner) }

    assert_match "AnonymousDashboardsController", error.message
    assert_match "widget_owner", error.message
  end

  # THE CATALOG IS CLASSES. Instantiating them is the concern's job — the
  # `ALL.map { |k| k.new(actor) }` wrapper every host wrote by hand.
  def test_the_offering_instantiates_the_catalog_with_the_actor
    controller = controller_class.new
    controller.define_singleton_method(:widget_owner) { :the_owner }

    offering = controller.send(:widget_offering)

    assert_equal [ "alpha" ], offering.map(&:key)
    assert_equal :the_owner, offering.first.context
  end

  # And GATES it. A widget the actor cannot see never reaches the picker, the
  # store, or a params lookup.
  def test_the_offering_drops_an_unauthorized_widget
    controller = controller_class(catalog: [ ALPHA, HIDDEN ]).new
    controller.define_singleton_method(:widget_owner) { :the_owner }

    assert_equal [ "alpha" ], controller.send(:widget_offering).map(&:key)
  end

  # The AUTHORIZATION actor is not the ROW owner. An app authorising through
  # Pundit gates on `pundit_user` while the rows belong to `current_user`, and
  # folding the two would break it on day one.
  def test_widget_actor_can_differ_from_widget_owner
    controller = controller_class.new
    controller.define_singleton_method(:widget_owner) { :row_owner }
    controller.define_singleton_method(:widget_actor) { :pundit_user }

    assert_equal :pundit_user, controller.send(:widget_offering).first.context
  end

  def test_the_dashboard_key_defaults_to_the_controller_path
    assert_equal "dashboards", controller_class.widget_dashboard_key
    assert_equal "today", controller_class(dashboard_key: "today").widget_dashboard_key
  end

  # BALI'S TEMPLATES SIT BEHIND THE CONTROLLER'S OWN, which is what lets a host
  # render nothing and still get a dashboard, then override either page by
  # creating the file. Same mechanism a subclassed controller uses.
  def test_bali_templates_are_looked_up_after_the_controllers_own
    prefixes = controller_class._prefixes

    assert_equal "bali/dashboard_widgets", prefixes.last
    assert_equal "dashboards", prefixes.first
  end
end
