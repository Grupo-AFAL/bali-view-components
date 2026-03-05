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

  def test_applies_fixed_sidebar_class_when_sidebar_present
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: true)) do |layout|
      layout.with_sidebar { "Sidebar" }
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout.app-layout--has-fixed-sidebar")
  end

  def test_does_not_apply_fixed_sidebar_class_without_sidebar
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: true)) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout--has-fixed-sidebar")
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

  def test_does_not_render_toast_container_when_flash_is_empty_hash
    render_inline(Bali::AppLayout::Component.new(flash: {})) do |layout|
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

  def test_modal_size_option_renders_with_size
    render_inline(Bali::AppLayout::Component.new(modal_size: :lg)) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("#main-modal")
    assert_selector(".modal-box.max-w-lg")
  end

  def test_drawer_size_option_renders_with_size
    render_inline(Bali::AppLayout::Component.new(drawer_size: :sm)) do |layout|
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

  def test_renders_navbar_when_provided
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_navbar { "Navigation bar" }
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout-navbar", text: "Navigation bar")
  end

  def test_does_not_render_navbar_when_not_provided
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout-navbar")
  end

  def test_applies_has_navbar_class_when_navbar_provided
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_navbar { "Nav" }
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout--has-navbar")
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

  def test_applies_custom_class_via_options
    render_inline(Bali::AppLayout::Component.new(class: "bg-base-200")) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout.bg-base-200")
  end

  def test_applies_data_attributes_via_options
    render_inline(Bali::AppLayout::Component.new(data: { controller: "theme-switcher" })) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout[data-controller*='theme-switcher']")
  end

  def test_merges_data_controller_with_modal_drawer
    render_inline(Bali::AppLayout::Component.new(
      modal: true,
      drawer: true,
      data: { controller: "theme-switcher" }
    )) do |layout|
      layout.with_body { "Content" }
    end
    # theme-switcher should be on the container, modal/drawer on main
    assert_selector(".app-layout[data-controller='theme-switcher']")
    assert_selector("main[data-controller='modal drawer']")
  end

  def test_renders_body_tag_as_root
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("body.app-layout")
  end

  def test_renders_full_layout_with_all_slots
    render_inline(Bali::AppLayout::Component.new(flash: { notice: "OK" })) do |layout|
      layout.with_banner { "Impersonating" }
      layout.with_navbar { "Nav" }
      layout.with_sidebar { "Sidebar" }
      layout.with_topbar { "Breadcrumbs" }
      layout.with_body { "Main content" }
    end
    assert_selector("body.app-layout")
    assert_selector(".app-layout-banner", text: "Impersonating")
    assert_selector(".app-layout-navbar", text: "Nav")
    assert_selector(".app-layout-main", text: "Sidebar")
    assert_selector(".app-layout-topbar", text: "Breadcrumbs")
    assert_text("Main content")
    assert_selector("#toast-notifications")
  end

  def test_applies_has_sidebar_class_when_sidebar_present
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_sidebar { "Sidebar" }
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout--has-sidebar")
  end

  def test_does_not_apply_has_sidebar_class_without_sidebar
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout--has-sidebar")
  end

  def test_toast_notifications_are_fixed_bottom_right
    render_inline(Bali::AppLayout::Component.new(flash: { notice: "Saved!" })) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("#toast-notifications.fixed.bottom-4.right-4.z-50")
  end

  def test_uses_flex_col_direction
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("body.app-layout.flex.flex-col")
  end

  def test_main_area_wrapper_exists
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout-main.flex.flex-1")
  end

  # --- body_container tests ---

  def test_default_body_container_is_wide
    render_inline(Bali::AppLayout::Component.new(modal: false, drawer: false)) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("main .app-layout-body-container.p-6", text: "Content")
  end

  def test_body_container_contained_preset
    render_inline(Bali::AppLayout::Component.new(body_container: :contained, modal: false, drawer: false)) do |layout|
      layout.with_body { "Content" }
    end
    container = page.find(".app-layout-body-container")
    assert_includes container[:class], "max-w-7xl"
    assert_includes container[:class], "mx-auto"
    assert_includes container[:class], "px-6"
  end

  def test_body_container_narrow_preset
    render_inline(Bali::AppLayout::Component.new(body_container: :narrow, modal: false, drawer: false)) do |layout|
      layout.with_body { "Content" }
    end
    container = page.find(".app-layout-body-container")
    assert_includes container[:class], "max-w-xl"
    assert_includes container[:class], "mx-auto"
    assert_includes container[:class], "px-4"
  end

  def test_body_container_full_preset
    render_inline(Bali::AppLayout::Component.new(body_container: :full, modal: false, drawer: false)) do |layout|
      layout.with_body { "Content" }
    end
    container = page.find(".app-layout-body-container")
    refute_includes container[:class], "max-w-"
    refute_includes container[:class], "mx-auto"
    refute_includes container[:class], "p-6"
  end

  def test_body_container_wide_preset
    render_inline(Bali::AppLayout::Component.new(body_container: :wide, modal: false, drawer: false)) do |layout|
      layout.with_body { "Content" }
    end
    container = page.find(".app-layout-body-container")
    assert_includes container[:class], "p-6"
    refute_includes container[:class], "max-w-"
    refute_includes container[:class], "mx-auto"
  end

  def test_body_container_unknown_symbol_raises_key_error
    assert_raises(KeyError) do
      render_inline(Bali::AppLayout::Component.new(body_container: :unknown, modal: false, drawer: false)) do |layout|
        layout.with_body { "Content" }
      end
    end
  end

  def test_body_container_does_not_affect_modal_drawer_placement
    render_inline(Bali::AppLayout::Component.new(
      body_container: :contained,
      modal: true, drawer: true
    )) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("main > .app-layout-body-container")
    assert_selector("main #main-modal")
    assert_selector("main #main-drawer")
  end

  def test_main_tag_no_longer_has_p6_hardcoded
    render_inline(Bali::AppLayout::Component.new(modal: false, drawer: false)) do |layout|
      layout.with_body { "Content" }
    end
    main_el = page.find("main")
    refute_includes main_el[:class], "p-6"
  end
end
