# frozen_string_literal: true

require "test_helper"

class BaliWidgetGridComponentTest < ComponentTestCase
  class Stock < Bali::Widget::Base
    sized :medium

    def self.title = "Low stock items"
    def self.short_title = "Low stock"
    def self.empty_message = "Nothing running low"

    def call
      Bali::Widget::Result.new(count: 1, view_all_path: "/items",
                               items: [ Bali::Widget::Row.new(title: "Tomatoes") ])
    end
  end

  def test_renders_the_two_composed_controllers_and_the_endpoint
    render_inline(Bali::WidgetGrid::Component.new(url: "/widget_layout"))

    assert_selector("[data-controller='bali-widget-grid edit-mode']", visible: :all)
    assert_selector("[data-bali-widget-grid-url-value='/widget_layout']", visible: :all)
  end

  def test_renders_one_card_per_widget_inside_the_sortable_grid
    render_inline(Bali::WidgetGrid::Component.new(url: "/widget_layout")) do |grid|
      grid.with_widget(Stock.new)
      grid.with_widget(Stock.new.with_size(:small))
    end

    assert_selector(".bali-widget-grid[data-controller~='sortable-list']", visible: :all)
    assert_selector(".bali-widget-grid > section[data-widget-key='stock']", count: 2, visible: :all)
  end

  def test_the_grid_listens_for_bali_s_own_sortable_event
    render_inline(Bali::WidgetGrid::Component.new(url: "/widget_layout")) do |grid|
      grid.with_widget(Stock.new)
    end

    assert_selector(
      ".bali-widget-grid[data-action*='bali:sortable-list:end->bali-widget-grid#reordered']",
      visible: :all
    )
  end

  def test_a_widget_can_replace_its_body
    render_inline(Bali::WidgetGrid::Component.new(url: "/widget_layout")) do |grid|
      grid.with_widget(Stock.new) do |card|
        card.with_body { "<p class='verdict'>All clear</p>".html_safe }
      end
    end

    assert_selector("p.verdict", text: "All clear")
  end

  def test_renders_the_add_tile_only_when_a_path_is_given
    render_inline(Bali::WidgetGrid::Component.new(url: "/l", add_path: "/widgets/edit")) do |grid|
      grid.with_widget(Stock.new)
    end

    assert_selector("a[href='/widgets/edit'][data-size='small']", visible: :all)
  end

  def test_omits_the_add_tile_when_no_path_is_given
    render_inline(Bali::WidgetGrid::Component.new(url: "/l")) do |grid|
      grid.with_widget(Stock.new)
    end

    assert_no_selector("a[data-size='small']", visible: :all)
  end

  def test_renders_an_empty_state_when_there_are_no_widgets
    render_inline(Bali::WidgetGrid::Component.new(url: "/l"))

    assert_selector(".empty-state-component")
    assert_no_selector(".bali-widget-grid")
  end

  def test_the_default_toolbar_offers_enter_and_a_hidden_leave
    render_inline(Bali::WidgetGrid::Component.new(url: "/l")) do |grid|
      grid.with_widget(Stock.new)
    end

    assert_selector("[data-edit-mode-target='enter'] button[data-action='edit-mode#enter']", visible: :all)
    assert_selector("[data-edit-mode-target='leave'][hidden] button[data-action='edit-mode#leave']", visible: :all)
  end

  def test_a_custom_toolbar_replaces_the_default
    render_inline(Bali::WidgetGrid::Component.new(url: "/l")) do |grid|
      grid.with_widget(Stock.new)
      grid.with_toolbar { "<h1>My dashboard</h1>".html_safe }
    end

    assert_selector("h1", text: "My dashboard")
    assert_no_selector("[data-edit-mode-target='enter']", visible: :all)
  end

  def test_renders_one_announcer_shared_by_both_controllers
    render_inline(Bali::WidgetGrid::Component.new(url: "/l"))

    assert_selector(
      "[role='status'][aria-live='polite'][data-bali-widget-grid-target='announcer'][data-edit-mode-target='announcer']",
      visible: :all
    )
  end
end
