# frozen_string_literal: true

require "test_helper"

class BaliBreadcrumbComponentTest < ComponentTestCase
  def test_basic_rendering_renders_breadcrumb_with_daisyui_classes
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Home", href: "/home")
      c.with_item(name: "Section", href: "/home/section")
      c.with_item(name: "Page")
    end
    assert_selector("nav.breadcrumbs.text-sm")
    assert_selector('li a[href="/home"]', text: "Home")
    assert_selector('li a[href="/home/section"]', text: "Section")
    assert_selector("li span", text: "Page")
  end

  def test_basic_rendering_renders_active_item_as_non_clickable_span
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Page", href: "/page", active: true)
    end
    assert_selector("li span.cursor-default", text: "Page")
  end

  def test_basic_rendering_auto_activates_item_when_href_is_nil
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Current Page")
    end
    assert_selector("li span.cursor-default", text: "Current Page")
    assert_no_selector("li a")
  end

  def test_accessibility_has_aria_label_on_nav_element
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Home", href: "/home")
    end
    assert_selector('nav[aria-label="Breadcrumb"]')
  end

  def test_accessibility_adds_aria_current_page_to_active_item
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Home", href: "/home")
      c.with_item(name: "Current Page")
    end
    assert_selector('li span[aria-current="page"]', text: "Current Page")
  end

  def test_accessibility_marks_only_the_last_crumb_as_current_when_another_has_no_link
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Settings", icon: "settings")
      c.with_item(name: "Warehouses", icon: "warehouse")
    end
    assert_selector('[aria-current="page"]', count: 1)
    assert_selector('li:last-child span[aria-current="page"]', text: "Warehouses")
    assert_selector("li:first-child span.cursor-default:not([aria-current])", text: "Settings")
  end

  def test_accessibility_never_marks_an_item_with_active_false_as_current
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Home", href: "/home")
      c.with_item(name: "Archive", active: false)
    end
    assert_selector("li span", text: "Archive")
    assert_no_selector("[aria-current]")
  end

  def test_accessibility_marks_no_crumb_as_current_when_the_last_one_links
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Movies", href: "/movies")
      c.with_item(name: "The Matrix", href: "/movies/1")
    end
    assert_selector('li a[href="/movies/1"]', text: "The Matrix")
    assert_no_selector("[aria-current]")
  end

  def test_accessibility_adds_aria_current_page_to_explicitly_active_item
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Page", href: "/page", active: true)
    end
    assert_selector('li span[aria-current="page"]', text: "Page")
  end

  def test_wires_the_breadcrumb_controller_to_the_scrolling_nav
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Home", href: "/home")
    end
    assert_selector('nav.overflow-x-auto[data-controller="breadcrumb"]' \
                    '[data-action="scroll->breadcrumb#update"]')
  end

  def test_with_icons_renders_breadcrumb_items_with_icons
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Home", href: "/home", icon: "home")
    end
    assert_selector("li a", text: "Home")
    assert_selector("li a svg")
  end

  def test_with_icons_renders_icon_on_non_link_items
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Current", icon: "home")
    end
    assert_selector("li span", text: "Current")
    assert_selector("li span svg")
  end

  def test_custom_classes_merges_custom_classes_on_container
    render_inline(Bali::Breadcrumb::Component.new(class: "my-custom-class")) do |c|
      c.with_item(name: "Home", href: "/home")
    end
    assert_selector("nav.breadcrumbs.my-custom-class")
  end

  def test_custom_classes_merges_custom_classes_on_item
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Home", href: "/home", class: "item-custom")
    end
    assert_selector("li.item-custom")
  end

  def test_link_behavior_renders_as_link_when_href_provided_and_not_active
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Section", href: "/section")
    end
    assert_selector('li a[href="/section"]', text: "Section")
    assert_selector("li a.no-underline")
  end

  def test_link_behavior_renders_as_span_when_active_even_with_href
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Section", href: "/section", active: true)
    end
    assert_selector("li span", text: "Section")
    assert_no_selector("li a")
  end

  def test_link_behavior_allows_explicit_active_false_to_keep_link_behavior
    render_inline(Bali::Breadcrumb::Component.new) do |c|
      c.with_item(name: "Current", active: false, href: "/current")
    end
    assert_selector('li a[href="/current"]', text: "Current")
  end
end
