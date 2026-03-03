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

  def test_renders_toast_notifications_when_flash_is_provided
    render_inline(Bali::AppLayout::Component.new(flash: { notice: "Saved!" })) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("#toast-notifications")
    assert_text("Saved!")
  end

  def test_does_not_render_toast_container_when_flash_is_nil
    render_inline(Bali::AppLayout::Component.new(flash: nil)) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector("#toast-notifications")
  end

  def test_renders_modal_shell_by_default
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("#main-modal")
  end

  def test_renders_drawer_shell_by_default
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("#main-drawer")
  end

  def test_does_not_render_modal_when_disabled
    render_inline(Bali::AppLayout::Component.new(modal: false)) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector("#main-modal")
  end

  def test_does_not_render_drawer_when_disabled
    render_inline(Bali::AppLayout::Component.new(drawer: false)) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector("#main-drawer")
  end

  def test_modal_hash_option_renders_with_size
    render_inline(Bali::AppLayout::Component.new(modal: { size: :lg })) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("#main-modal")
    assert_selector(".modal-box.max-w-lg")
  end

  def test_drawer_hash_option_renders_with_size
    render_inline(Bali::AppLayout::Component.new(drawer: { size: :sm })) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("#main-drawer")
    assert_selector(".drawer-panel.max-w-sm")
  end

  def test_adds_modal_and_drawer_stimulus_controllers_to_main
    render_inline(Bali::AppLayout::Component.new(modal: true, drawer: true)) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("main[data-controller='modal drawer']")
  end

  def test_no_data_controller_when_both_modal_and_drawer_disabled
    render_inline(Bali::AppLayout::Component.new(modal: false, drawer: false)) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector("main[data-controller]")
  end

  def test_renders_banner_when_provided
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_banner { "You are impersonating John" }
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout-banner", text: "You are impersonating John")
  end

  def test_does_not_render_banner_when_not_provided
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout-banner")
  end
end
