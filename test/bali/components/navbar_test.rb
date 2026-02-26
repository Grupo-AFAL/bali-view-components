# frozen_string_literal: true

require "test_helper"

class Bali_Navbar_ComponentTest < ComponentTestCase
  #


  def test_without_fullscreen_renders_navbar_component
    render_inline(Bali::Navbar::Component.new(fullscreen: false)) do |c|
    c.with_brand { '<a class="btn btn-ghost text-xl">Bali</a>'.html_safe }
    c.with_menu do |menu|
    menu.with_start_items([
    { name: "Tech Stack", href: "#" }, { name: "Projects", href: "#" }, { name: "Team", href: "#" }, { name: "Open Positions", href: "#" }
    ])
    end
    end
    assert_selector("a.btn.btn-ghost", text: "Bali")
    assert_selector("a", text: "Tech Stack")
    assert_selector("a", text: "Projects")
    assert_selector("a", text: "Team")
    assert_selector("a", text: "Open Positions")
    assert_selector("button.btn.btn-ghost")
    # Non-fullscreen: centered with max-width constraint
    assert_selector("nav div.max-w-7xl.mx-auto")
  end
  #


  def test_with_fullscreen_renders_navbar_component_with_fullscreen
    render_inline(Bali::Navbar::Component.new(fullscreen: true)) do |c|
    c.with_brand { '<a class="btn btn-ghost text-xl">Bali</a>'.html_safe }
    c.with_menu do |menu|
    menu.with_start_items([ { name: "Tech Stack", href: "#" } ])
    end
    end
    assert_selector("a.btn.btn-ghost", text: "Bali")
    assert_selector("a", text: "Tech Stack")
    assert_selector("button.btn.btn-ghost")
    # Fullscreen: edge-to-edge, no max-width constraint
    assert_no_selector("nav div.max-w-6xl")
  end
  #


  def test_with_transparency_enabled_renders_navbar_component_with_transparency_data_attribute
    render_inline(Bali::Navbar::Component.new(transparency: true)) do |c|
    c.with_brand { '<a class="btn btn-ghost text-xl">Bali</a>'.html_safe }
    c.with_menu do |menu|
    menu.with_start_items([ { name: "Tech Stack", href: "#" } ])
    end
    end
    assert_selector("a.btn.btn-ghost", text: "Bali")
    assert_selector('[data-navbar-allow-transparency-value="true"]')
  end
  #

  def test_with_custom_burger_button_renders_navbar_component_with_custom_burger
    render_inline(Bali::Navbar::Component.new) do |c|
    c.with_brand { '<a class="btn btn-ghost text-xl">Bali</a>'.html_safe }
    c.with_burger(class: "custom-burger")
    c.with_menu do |menu|
    menu.with_start_items([ { name: "Tech Stack", href: "#" } ])
    end
    end
    assert_selector("a.btn.btn-ghost", text: "Bali")
    assert_selector("button.btn.btn-ghost.custom-burger")
  end
  #

  def test_with_multiple_menu_and_burgers_renders_navbar_component_with_multiple_menus
    render_inline(Bali::Navbar::Component.new) do |c|
    c.with_brand { '<a class="btn btn-ghost text-xl">Bali</a>'.html_safe }
    c.with_burger(class: "custom-burger")
    c.with_burger(type: :alt)
    c.with_menu do |menu|
    menu.with_start_items([ { name: "Tech Stack", href: "#" } ])
    end
    c.with_menu(type: :alt) do |menu|
    menu.with_end_items([ { name: "About us", href: "#" } ])
    end
    end
    assert_selector("a.btn.btn-ghost", text: "Bali")
    assert_selector('[data-navbar-target="burger"]')
    assert_selector('[data-navbar-target="altBurger"]')
    assert_selector('[data-navbar-target="menu"]')
    assert_selector('[data-navbar-target="altMenu"]')
  end
  #

  Bali::Navbar::Component::COLORS.each do |color, classes|
  define_method("test_with_colors_renders_#{color}_#{color}") do
    render_inline(Bali::Navbar::Component.new(color: color))
    classes.split.each do |css_class|
    assert_selector("nav.navbar.#{css_class}")
  end
  end


  def test_renders_base_color_by_default
    render_inline(Bali::Navbar::Component.new)
    assert_selector("nav.navbar.bg-base-100")
  end
  def test_skips_color_classes_for_unknown_symbol
    render_inline(Bali::Navbar::Component.new(color: :invalid))
    assert_selector("nav.navbar")
    assert_no_selector("nav.navbar.bg-base-100")
  end
  def test_skips_color_classes_when_color_is_nil_allowing_custom_class
    render_inline(Bali::Navbar::Component.new(color: nil, class: "bg-indigo-600 text-white"))
    assert_selector("nav.navbar.bg-indigo-600.text-white")
    assert_no_selector("nav.navbar.bg-base-100")
  end
  end

  #

  def test_accessibility_has_navigation_role
    render_inline(Bali::Navbar::Component.new)
    assert_selector('nav[role="navigation"]')
  end
  def test_accessibility_has_aria_label
    render_inline(Bali::Navbar::Component.new)
    assert_selector("nav[aria-label]")
  end
  def test_accessibility_burger_button_has_aria_label
    render_inline(Bali::Navbar::Component.new)
    assert_selector("button[aria-label]")
  end
  #

  def test_data_attributes_includes_stimulus_controller
    render_inline(Bali::Navbar::Component.new)
    assert_selector('nav[data-controller="navbar"]')
  end
  def test_data_attributes_includes_throttle_interval_value
    render_inline(Bali::Navbar::Component.new)
    assert_selector('nav[data-navbar-throttle-interval-value="100"]')
  end
  #

  def test_custom_options_passes_through_custom_classes
    render_inline(Bali::Navbar::Component.new(class: "custom-navbar"))
    assert_selector("nav.navbar.custom-navbar")
  end
  def test_custom_options_passes_through_data_attributes
    render_inline(Bali::Navbar::Component.new(data: { testid: "nav" }))
    assert_selector('nav[data-testid="nav"]')
  end
  def test_custom_options_supports_container_class_option
    render_inline(Bali::Navbar::Component.new(container_class: "custom-container"))
    assert_selector("nav div.custom-container")
  end
end

class Bali_Navbar_Menu_ComponentTest < ComponentTestCase
  def test_renders_with_daisyui_menu_classes
    render_inline(Bali::Navbar::Menu::Component.new) do |menu|
    menu.with_start_item(name: "Link", href: "#")
    end
    # Outer wrapper is hidden on mobile, visible on desktop (lg:flex)
    assert_selector("div.hidden")
    # Menu uses responsive horizontal classes
    assert_selector("ul.menu")
  end
  def test_renders_end_items_in_flex_container_with_ml_auto_on_desktop
    render_inline(Bali::Navbar::Menu::Component.new) do |menu|
    menu.with_end_item(name: "End", href: "#")
    end
    # ml-auto is responsive (lg:ml-auto)
    assert_selector('div[class*="lg:ml-auto"] a', text: "End")
  end
  def test_sets_correct_data_navbar_target_for_main_menu_with_start_items
    render_inline(Bali::Navbar::Menu::Component.new(type: :main)) do |menu|
    menu.with_start_item(name: "Link", href: "#")
    end
    assert_selector('div[data-navbar-target="menu"]')
  end
  def test_sets_correct_data_navbar_target_for_alt_menu_with_end_items
    render_inline(Bali::Navbar::Menu::Component.new(type: :alt)) do |menu|
    menu.with_end_item(name: "Action", href: "#")
    end
    assert_selector('div[data-navbar-target="altMenu"]')
  end
end

class Bali_Navbar_Item_ComponentTest < ComponentTestCase
  def test_renders_as_anchor_by_default
    render_inline(Bali::Navbar::Item::Component.new(name: "Link", href: "#"))
    assert_selector('a[href="#"]', text: "Link")
  end
  def test_renders_with_custom_tag
    render_inline(Bali::Navbar::Item::Component.new(tag_name: :div, name: "Div"))
    assert_selector("div", text: "Div")
  end
  def test_renders_content_block
    render_inline(Bali::Navbar::Item::Component.new(tag_name: :div)) { "Block content" }
    assert_selector("div", text: "Block content")
  end
  def test_passes_through_custom_attributes
    render_inline(Bali::Navbar::Item::Component.new(name: "Link", href: "#", class: "custom"))
    assert_selector("a.custom")
  end
end

class Bali_Navbar_Burger_ComponentTest < ComponentTestCase
  def test_renders_button_with_default_icon
    render_inline(Bali::Navbar::Burger::Component.new)
    assert_selector("button.btn.btn-ghost")
    assert_selector("svg")
  end
  def test_has_aria_label_for_accessibility
    render_inline(Bali::Navbar::Burger::Component.new)
    assert_selector("button[aria-label]")
  end
  def test_sets_correct_data_attributes_for_main_type
    render_inline(Bali::Navbar::Burger::Component.new(type: :main))
    assert_selector('[data-navbar-target="burger"]')
    assert_selector('[data-action*="navbar#toggleMenu"]')
  end
  def test_sets_correct_data_attributes_for_alt_type
    render_inline(Bali::Navbar::Burger::Component.new(type: :alt))
    assert_selector('[data-navbar-target="altBurger"]')
    assert_selector('[data-action*="navbar#toggleAltMenu"]')
  end
  def test_renders_custom_content
    render_inline(Bali::Navbar::Burger::Component.new) { "Custom icon" }
    assert_selector("button", text: "Custom icon")
  end
  def test_passes_through_custom_classes
    render_inline(Bali::Navbar::Burger::Component.new(class: "custom-burger"))
    assert_selector("button.btn.btn-ghost.custom-burger")
  end
  #

  def test_with_href_renders_as_a_link
    render_inline(Bali::Navbar::Burger::Component.new(href: "/menu"))
    assert_selector('a.btn.btn-ghost[href="/menu"]')
    assert_no_selector("button")
  end
  def test_with_href_renders_with_default_icon
    render_inline(Bali::Navbar::Burger::Component.new(href: "/menu"))
    assert_selector("a svg")
  end
  def test_with_href_renders_custom_content
    render_inline(Bali::Navbar::Burger::Component.new(href: "/menu")) { "Menu" }
    assert_selector("a", text: "Menu")
  end
  def test_with_href_has_aria_label_for_accessibility
    render_inline(Bali::Navbar::Burger::Component.new(href: "/menu"))
    assert_selector("a[aria-label]")
  end
  def test_with_href_does_not_add_stimulus_data_attributes
    render_inline(Bali::Navbar::Burger::Component.new(href: "/menu", type: :main))
    assert_no_selector("[data-navbar-target]")
    assert_no_selector("[data-action]")
  end
end
