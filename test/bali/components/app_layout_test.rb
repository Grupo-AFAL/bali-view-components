# frozen_string_literal: true

require "test_helper"

class BaliAppLayoutComponentTest < ComponentTestCase
  def test_renders_the_app_layout_container
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_sidebar do
        render_inline(Bali::SideMenu::Component.new(current_path: "/")) do |menu|
          menu.with_list do |list|
            list.with_item(name: "Dashboard", href: "/")
          end
        end
      end
      layout.with_body { "Main content" }
    end
    assert_selector(".app-layout")
    assert_text("Main content")
  end

  def test_renders_content_in_main_area
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Hello world" }
    end
    assert_selector(".app-layout-content", text: "Hello world")
  end

  def test_renders_without_sidebar
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "No sidebar" }
    end
    assert_selector(".app-layout")
    assert_selector(".app-layout-content", text: "No sidebar")
    assert_no_selector(".side-menu-component")
  end

  def test_renders_topbar_when_provided
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_topbar { "Search bar" }
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout-topbar", text: "Search bar")
  end

  def test_does_not_render_topbar_when_not_provided
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout-topbar")
  end

  def test_accepts_custom_classes
    render_inline(Bali::AppLayout::Component.new(class: "custom-class")) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout.custom-class")
  end

  def test_applies_fixed_sidebar_class
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: true)) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout.app-layout--has-fixed-sidebar")
  end

  def test_does_not_apply_fixed_sidebar_class_by_default
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout--has-fixed-sidebar")
  end
end
