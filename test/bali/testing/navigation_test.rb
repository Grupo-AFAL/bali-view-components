# frozen_string_literal: true

require "test_helper"
require "bali/testing/navigation"

class BaliTestingNavigationTest < ActiveSupport::TestCase
  include Bali::Testing::Navigation

  ROUTES = ActionDispatch::Routing::RouteSet.new.tap do |routes|
    routes.draw do
      get "up" => "rails/health#show"
      root "dashboard#index"
      namespace(:admin) { resources :movies, only: :index }
      mount Bali::Engine => "/bali"
    end
  end

  def navigation(&declaration)
    Class.new(Bali::Navigation) { class_eval(&declaration) }
  end

  def placed
    navigation do
      section(:work, title: "Work") { item :dashboard, title: "Dashboard", path: "/", controllers: %w[dashboard] }
      section(:admin, title: "Admin", controllers: %w[admin]) { item :movies, title: "Movies", path: "/admin/movies" }
    end
  end

  test "every navigable controller has a place; one not descending from the base is not asked" do
    assert_navigation_covers_routes placed, routes: ROUTES
  end

  test "it names a controller without a place, and says where to put it" do
    nav = navigation do
      section(:work, title: "Work") { item :dashboard, title: "Dashboard", path: "/", controllers: %w[dashboard] }
    end

    error = assert_raises(Minitest::Assertion) { assert_navigation_covers_routes nav, routes: ROUTES }

    assert_match "admin/movies has no place", error.message
    assert_match "or to `outside_menu`", error.message
  end

  test "outside_menu is a place" do
    nav = navigation do
      section(:work, title: "Work") { item :dashboard, title: "Dashboard", path: "/", controllers: %w[dashboard] }
      outside_menu "admin"
    end

    assert_navigation_covers_routes nav, routes: ROUTES
  end

  test "it names an entry that reaches no routed controller" do
    nav = placed
    nav.outside_menu "ghosts"

    error = assert_raises(Minitest::Assertion) { assert_navigation_covers_routes nav, routes: ROUTES }

    assert_match "ghosts reaches no routed controller", error.message
  end

  test "the base decides what is navigable, and an engine's controllers are walked" do
    error = assert_raises(Minitest::Assertion) do
      assert_navigation_covers_routes placed, base: ActionController::Base, routes: ROUTES
    end

    assert_match "rails/health", error.message
    assert_match "bali/saved_views", error.message
  end

  test "it names a title missing in the locale" do
    nav = navigation do
      section(:work) { item :dashboard, title: "Dashboard", path: "/" }
    end

    error = assert_raises(Minitest::Assertion) { assert_navigation_translated nav, locale: :es }

    assert_match "navigation.sections.work", error.message
    assert_no_match "dashboard", error.message
  end
end
