# frozen_string_literal: true

require "test_helper"

class BaliWidgetGridComponentTest < ComponentTestCase
  # A real pattern subclass. Not `Bali::Widget::Base` directly — the
  # architecture is that a widget IS one of the four patterns, and a test class
  # that skips the ladder is testing a widget no host could write.
  class Stock < Bali::Widget::ListBase
    default_size :medium

    title "Low stock items"
    short_title "Low stock"
    empty_message "Nothing running low"

    row_title :title
    view_all_path { "/items" }

    def count = 1

    def scope = [ Struct.new(:title).new("Tomatoes") ]

    private

    # The grid only ever renders these; a relation would mean a table this test
    # does not otherwise need.
    def previewable = scope
  end

  def test_renders_the_two_composed_controllers_and_the_endpoint
    render_inline(Bali::WidgetGrid::Component.new(url: "/widget_layout"))

    assert_selector("[data-controller='bali-widget-grid bali-widget-grid-edit-mode']", visible: :all)
    assert_selector("[data-bali-widget-grid-url-value='/widget_layout']", visible: :all)
  end

  # Removing announces a running total the way `move` does, and Spanish does not
  # share a verb across "queda 1 widget" and "quedan 3 widgets" — so the count
  # cannot be one interpolated string. The component resolves i18n at
  # `initialize`, where it cannot know a count, so all three forms are emitted
  # and the controller picks.
  def test_emits_every_removal_announcement_the_controller_has_to_choose_between
    render_inline(Bali::WidgetGrid::Component.new(url: "/widget_layout"))

    assert_selector("[data-bali-widget-grid-removed-one-text-value]", visible: :all)
    assert_selector("[data-bali-widget-grid-removed-other-text-value]", visible: :all)
    assert_selector("[data-bali-widget-grid-removed-last-text-value]", visible: :all)
  end

  # The empty case is its own string rather than "0 widgets remaining", which
  # would name a state the user is about to not be in: an emptied grid means
  # "never chose", so the server restores every authorized widget and the
  # controller reloads for them.
  def test_the_last_removal_announces_the_restore_rather_than_a_count_of_zero
    render_inline(Bali::WidgetGrid::Component.new(url: "/widget_layout"))

    assert_no_selector("[data-bali-widget-grid-removed-last-text-value*='%{total}']", visible: :all)
  end

  # A component has no business claiming a bare, generic `?editing` from inside a
  # host's URL — they may already use it. Exposed in Ruby because a host renders
  # this component; it does not hand-write the data attributes.
  def test_the_editing_param_is_configurable
    render_inline(Bali::WidgetGrid::Component.new(url: "/w", editing_param: "arranging"))

    assert_selector("[data-bali-widget-grid-edit-mode-param-value='arranging']", visible: :all)
  end

  def test_the_editing_param_defaults_to_editing
    render_inline(Bali::WidgetGrid::Component.new(url: "/w"))

    assert_selector("[data-bali-widget-grid-edit-mode-param-value='editing']", visible: :all)
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

  def test_the_empty_state_offers_a_way_to_add_the_first_widget
    render_inline(Bali::WidgetGrid::Component.new(url: "/l", add_path: "/widgets/edit"))

    assert_selector(".empty-state-component a[href='/widgets/edit']")
  end

  def test_the_empty_state_offers_no_cta_when_there_is_nowhere_to_add
    render_inline(Bali::WidgetGrid::Component.new(url: "/l"))

    assert_selector(".empty-state-component")
    assert_no_selector(".empty-state-component a")
  end

  def test_a_custom_empty_state_replaces_the_default
    render_inline(Bali::WidgetGrid::Component.new(url: "/l")) do |grid|
      grid.with_empty_state { "<p class='mine'>Nothing yet</p>".html_safe }
    end

    assert_selector("p.mine", text: "Nothing yet")
    assert_no_selector(".empty-state-component")
  end

  def test_the_wrapper_binds_escape_for_edit_mode
    render_inline(Bali::WidgetGrid::Component.new(url: "/l"))

    assert_selector("[data-action*='keydown@window->bali-widget-grid-edit-mode#keydown']", visible: :all)
  end

  def test_the_default_bar_offers_enter_and_a_hidden_leave
    render_inline(Bali::WidgetGrid::Component.new(url: "/l")) do |grid|
      grid.with_widget(Stock.new)
    end

    assert_selector("[data-bali-widget-grid-edit-mode-target='enter'] button[data-action='bali-widget-grid-edit-mode#enter']", visible: :all)
    assert_selector("[data-bali-widget-grid-edit-mode-target='leave'][hidden] button[data-action='bali-widget-grid-edit-mode#leave']", visible: :all)
  end

  def test_a_custom_heading_replaces_the_hint_but_keeps_the_edit_controls
    render_inline(Bali::WidgetGrid::Component.new(url: "/l")) do |grid|
      grid.with_widget(Stock.new)
      grid.with_heading { "<h1>My dashboard</h1>".html_safe }
    end

    assert_selector("h1", text: "My dashboard")
    # The grid is the only surface that offers edit mode; a custom heading must
    # not be able to delete the way in.
    assert_selector("[data-bali-widget-grid-edit-mode-target='enter'] button[data-action='bali-widget-grid-edit-mode#enter']", visible: :all)
  end

  def test_renders_one_announcer_shared_by_both_controllers
    render_inline(Bali::WidgetGrid::Component.new(url: "/l"))

    assert_selector(
      "[role='status'][aria-live='polite'][data-bali-widget-grid-target='announcer'][data-bali-widget-grid-edit-mode-target='announcer']",
      visible: :all
    )
  end
end
