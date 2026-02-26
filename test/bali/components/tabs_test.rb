# frozen_string_literal: true

require "test_helper"

class Bali_Tabs_ComponentTest < ComponentTestCase
  #

  def test_basic_rendering_renders_tabs_with_content
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab 1", active: true) { "<p>Tab 1 content</p>".html_safe }
    c.with_tab(title: "Tab 2") { "<p>Tab 2 content</p>".html_safe }
    end
    assert_selector(".tabs-component")
    assert_selector("a.tab.tab-active", text: "Tab 1")
    assert_selector("a.tab", text: "Tab 2")
    assert_selector("p", text: "Tab 1 content")
    assert_selector(".hidden p", text: "Tab 2 content")
  end
  def test_basic_rendering_renders_tabs_with_tablist_role_for_accessibility
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab 1", active: true) { "Content" }
    end
    assert_selector('[role="tablist"]')
    assert_selector('a[role="tab"]')
  end
  def test_basic_rendering_renders_correct_aria_attributes
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab 1", active: true) { "Content 1" }
    c.with_tab(title: "Tab 2") { "Content 2" }
    end
    # Active tab
    assert_selector('a[role="tab"][aria-selected="true"][tabindex="0"]')
    # Inactive tab
    assert_selector('a[role="tab"][aria-selected="false"][tabindex="-1"]')
    # Tab panels
    assert_selector('[role="tabpanel"][aria-labelledby="tab-0"]')
    assert_selector('[role="tabpanel"][aria-labelledby="tab-1"]')
  end
  def test_basic_rendering_sets_up_stimulus_controller
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector('[data-controller="tabs"]')
  end
  #

  def test_styles_renders_border_style_by_default
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs.tabs-border")
  end
  def test_styles_renders_default_style_with_no_extra_classes
    render_inline(Bali::Tabs::Component.new(style: :default)) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs")
    assert_no_selector(".tabs-border")
    assert_no_selector(".tabs-box")
    assert_no_selector(".tabs-lift")
  end
  def test_styles_renders_box_style
    render_inline(Bali::Tabs::Component.new(style: :box)) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs.tabs-box")
  end
  def test_styles_renders_lift_style
    render_inline(Bali::Tabs::Component.new(style: :lift)) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs.tabs-lift")
  end
  def test_styles_handles_invalid_style_gracefully
    render_inline(Bali::Tabs::Component.new(style: :invalid)) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs")
  end
  #

  def test_sizes_renders_xs_size
    render_inline(Bali::Tabs::Component.new(size: :xs)) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs.tabs-xs")
  end
  def test_sizes_renders_small_size
    render_inline(Bali::Tabs::Component.new(size: :sm)) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs.tabs-sm")
  end
  def test_sizes_renders_medium_size_with_no_extra_classes
    render_inline(Bali::Tabs::Component.new(size: :md)) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs")
    assert_no_selector(".tabs-md")
  end
  def test_sizes_renders_large_size
    render_inline(Bali::Tabs::Component.new(size: :lg)) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs.tabs-lg")
  end
  def test_sizes_renders_xl_size
    render_inline(Bali::Tabs::Component.new(size: :xl)) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs.tabs-xl")
  end
  def test_sizes_handles_invalid_size_gracefully
    render_inline(Bali::Tabs::Component.new(size: :invalid)) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs")
  end
  #

  def test_with_icons_renders_tabs_with_icon
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab", active: true, icon: "alert") { "<p>Tab content</p>".html_safe }
    end
    assert_selector("span.icon-component svg")
  end
  def test_with_icons_renders_tab_with_icon_but_no_title
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(icon: "settings", active: true) { "Content" }
    end
    assert_selector("a.tab span.icon-component")
    assert_selector("a.tab span", text: "")
  end
  #

  def test_with_href_full_page_navigation_renders_tabs_with_href_for_full_page_navigation
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab", href: "/")
    end
    assert_selector('a.tab[href="/"]')
  end
  def test_with_href_full_page_navigation_does_not_include_stimulus_data_attributes_when_href_is_present
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab", href: "/page")
    end
    assert_selector('a.tab[href="/page"]')
    assert_no_selector("a.tab[data-action]")
  end
  #

  def test_with_src_on_demand_loading_renders_tabs_with_src_for_lazy_loading
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab", src: "/content", active: true)
    end
    assert_selector('a.tab[data-tabs-src-param="/content"]')
  end
  def test_with_src_on_demand_loading_renders_tabs_with_reload_option
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab", src: "/content", reload: true, active: true)
    end
    assert_selector('a.tab[data-tabs-reload-param="true"]')
  end
  def test_with_src_on_demand_loading_defaults_reload_to_false
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab", src: "/content", active: true)
    end
    assert_selector('a.tab[data-tabs-reload-param="false"]')
  end
  #

  def test_options_passthrough_passes_custom_class_to_container
    render_inline(Bali::Tabs::Component.new(class: "custom-tabs")) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector(".tabs-component.custom-tabs")
  end
  def test_options_passthrough_passes_data_attributes_to_container
    render_inline(Bali::Tabs::Component.new(data: { testid: "my-tabs" })) do |c|
    c.with_tab(title: "Tab", active: true) { "Content" }
    end
    assert_selector('[data-testid="my-tabs"]')
  end
  def test_options_passthrough_passes_custom_options_to_tab_content
    render_inline(Bali::Tabs::Component.new) do |c|
    c.with_tab(title: "Tab", active: true, class: "custom-panel") { "Content" }
    end
    assert_selector('[role="tabpanel"].custom-panel')
  end
end
