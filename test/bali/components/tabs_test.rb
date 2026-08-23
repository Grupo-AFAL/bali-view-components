# frozen_string_literal: true

require "test_helper"

class BaliTabsComponentTest < ComponentTestCase
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

  # A set of links that leave the page is navigation, not a tab widget. The tab
  # roles used to survive into that markup, promising an `aria-controls` target
  # that does not exist.
  def test_navigation_mode_renders_a_nav_when_every_tab_has_an_href
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Tab 1", href: "/one")
      c.with_tab(title: "Tab 2", href: "/two")
    end

    assert_selector("nav.tabs")
    assert_no_selector('[role="tablist"]')
    assert_no_selector('[role="tab"]')
    assert_no_selector('[role="tabpanel"]')
  end

  def test_navigation_mode_marks_the_current_page
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Tab 1", href: "/one", active: true)
      c.with_tab(title: "Tab 2", href: "/two")
    end

    assert_selector('nav a[href="/one"][aria-current="page"]')
    assert_no_selector('nav a[href="/two"][aria-current]')
    assert_no_selector("nav a[aria-selected]")
  end

  def test_navigation_mode_names_the_nav
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Tab", href: "/one")
    end

    assert_selector('nav[aria-label="Section navigation"]')
  end

  def test_navigation_mode_accepts_a_custom_nav_label
    render_inline(Bali::Tabs::Component.new(label: "Project sections")) do |c|
      c.with_tab(title: "Tab", href: "/one")
    end

    assert_selector('nav[aria-label="Project sections"]')
  end

  def test_navigation_mode_translates_the_default_nav_label
    I18n.with_locale(:es) do
      render_inline(Bali::Tabs::Component.new) do |c|
        c.with_tab(title: "Tab", href: "/one")
      end

      assert_selector('nav[aria-label="Navegación de secciones"]')
    end
  end

  # Navigation has no panels to swap, so the Stimulus controller has no work.
  def test_navigation_mode_drops_the_tabs_controller
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Tab", href: "/one")
    end

    assert_no_selector('[data-controller="tabs"]')
  end

  # Half links leaving the page and half tabs owning a panel, all inside one
  # `role="tablist"`: ARIA describes no such widget, and this used to render in
  # silence.
  def test_mixing_href_and_panels_raises
    error = assert_raises(ArgumentError) do
      render_inline(Bali::Tabs::Component.new) do |c|
        c.with_tab(title: "Link", href: "/one")
        c.with_tab(title: "Panel", active: true) { "Content" }
      end
    end

    assert_includes(error.message, "Bali::Tabs::Component")
    assert_includes(error.message, "href:")
    assert_includes(error.message, "src:")
  end

  def test_an_empty_component_still_renders_a_tablist
    render_inline(Bali::Tabs::Component.new)

    assert_selector('[role="tablist"]')
    assert_no_selector("nav")
  end

  def test_count_renders_a_badge_after_the_title
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Inbox", active: true, count: 12) { "Content" }
    end

    assert_selector("a.tab span.badge", text: "12")
    # The count is information, not decoration: it stays in the accessible name.
    assert_selector("a.tab", text: /Inbox\s+12/)
  end

  def test_count_of_zero_still_renders
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Done", active: true, count: 0) { "Content" }
    end

    assert_selector("a.tab span.badge", text: "0")
  end

  def test_count_accepts_a_string
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Inbox", active: true, count: "99+") { "Content" }
    end

    assert_selector("a.tab span.badge", text: "99+")
  end

  def test_without_count_there_is_no_badge
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Tab", active: true) { "Content" }
    end

    assert_no_selector("a.tab .badge")
  end

  def test_count_renders_in_navigation_mode
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Mine", href: "/mine", count: 3)
      c.with_tab(title: "Team", href: "/team", count: 12)
    end

    assert_selector('nav a[href="/mine"] span.badge', text: "3")
    assert_selector('nav a[href="/team"] span.badge', text: "12")
  end

  # A count is sometimes an alarm, not just an amount: "3 blocking questions"
  # should not look like "3 items". `count_color:` takes the same semantic
  # table every other `color:` does (#1064).
  def test_count_color_paints_the_badge
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Discovery", active: true, count: 3, count_color: :warning) { "Content" }
    end

    assert_selector("a.tab span.badge.badge-warning", text: "3")
  end

  def test_count_color_paints_the_badge_in_navigation_mode
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Mine", href: "/mine", count: 3, count_color: :error)
    end

    assert_selector('nav a[href="/mine"] span.badge.badge-error', text: "3")
  end

  def test_without_count_color_the_badge_stays_neutral
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Inbox", active: true, count: 12) { "Content" }
    end

    badge = page.find("a.tab span.badge")
    assert_equal("badge badge-sm ml-1", badge[:class])
  end

  def test_count_color_rejects_an_unknown_name
    error = assert_raises(ArgumentError) do
      Bali::Tabs::Tab::Component.new(title: "Inbox", count: 3, count_color: :danger)
    end
    assert_match(/count_color/, error.message)
  end

  # `Bali::Color.name!` validates against NAMES while the badge class is a bare
  # COUNT_COLORS lookup, and `class_names` drops a nil silently — so a name
  # added to NAMES without a matching entry here would validate and then render
  # neutral. Same guard Timeline keeps on its COLORS maps.
  def test_count_color_covers_every_bali_color_name
    assert(Bali::Tabs::Tab::Component::COUNT_COLORS.frozen?)
    assert_equal(Bali::Color::NAMES, Bali::Tabs::Tab::Component::COUNT_COLORS.keys)

    Bali::Color::NAMES.each do |name|
      render_inline(Bali::Tabs::Component.new) do |c|
        c.with_tab(title: "Tab", active: true, count: 1, count_color: name) { "Content" }
      end
      assert_selector("a.tab span.badge.badge-#{name}", text: "1")
    end
  end

  # In navigation mode there is no panel div for the tab options to land on,
  # so they used to vanish. They belong to the `<a>`.
  def test_navigation_mode_passes_tab_options_to_the_link
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Tab", href: "/one", class: "custom-tab", data: { bali_test: "tab-link" })
    end

    assert_selector('nav a.tab.custom-tab[href="/one"][data-bali-test="tab-link"]')
  end

  def test_navigation_mode_link_does_not_inherit_the_hidden_panel_class
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Tab 1", href: "/one")
      c.with_tab(title: "Tab 2", href: "/two")
    end

    assert_no_selector("nav a.hidden", visible: :all)
  end

  def test_navigation_mode_emits_turbo_action_advance_by_default
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Tab", href: "/one")
    end

    assert_selector('nav a[href="/one"][data-turbo-action="advance"]')
  end

  def test_navigation_mode_turbo_action_false_omits_the_attribute
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Tab", href: "/one", turbo_action: false)
    end

    assert_selector('nav a[href="/one"]')
    assert_no_selector("nav a[data-turbo-action]")
  end

  def test_navigation_mode_passes_a_custom_turbo_action_through
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Tab", href: "/one", turbo_action: :replace)
    end

    assert_selector('nav a[href="/one"][data-turbo-action="replace"]')
  end

  def test_panel_mode_does_not_emit_turbo_action
    render_inline(Bali::Tabs::Component.new) do |c|
      c.with_tab(title: "Tab", active: true) { "Content" }
    end

    assert_no_selector("a.tab[data-turbo-action]")
  end
end
