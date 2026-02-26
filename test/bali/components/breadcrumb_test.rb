# frozen_string_literal: true

require "test_helper"

class Bali_Breadcrumb_ComponentTest < ComponentTestCase
  #

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
  #

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
  def test_accessibility_adds_aria_current_page_to_explicitly_active_item
    render_inline(Bali::Breadcrumb::Component.new) do |c|
    c.with_item(name: "Page", href: "/page", active: true)
    end
    assert_selector('li span[aria-current="page"]', text: "Page")
  end
  #

  def test_with_icons_renders_breadcrumb_items_with_icons
    render_inline(Bali::Breadcrumb::Component.new) do |c|
    c.with_item(name: "Home", href: "/home", icon_name: "home")
    end
    assert_selector("li a", text: "Home")
    assert_selector("li a svg")
  end
  def test_with_icons_renders_icon_on_non_link_items
    render_inline(Bali::Breadcrumb::Component.new) do |c|
    c.with_item(name: "Current", icon_name: "home")
    end
    assert_selector("li span", text: "Current")
    assert_selector("li span svg")
  end
  #

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
  #

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
