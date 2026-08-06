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
    # The host's controller keeps the container, next to the layout's own;
    # modal/drawer stay on main.
    assert_selector(".app-layout[data-controller='app-layout theme-switcher']")
    assert_selector("main[data-controller='modal drawer']")
  end

  def test_the_layout_controller_is_attached_even_without_a_banner
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end

    assert_selector("body.app-layout[data-controller='app-layout']")
    assert_no_selector("[data-app-layout-target='banner']")
  end

  def test_the_banner_is_the_target_the_controller_measures
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_banner { "You are impersonating John" }
      layout.with_body { "Content" }
    end

    assert_selector(".app-layout-banner[data-app-layout-target='banner']",
                    text: "You are impersonating John")
  end

  # One slot, one target, whatever the host stacks inside it: the controller
  # measures the strip, not the banners, so two banners need no second target.
  def test_stacked_banners_share_the_one_target
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_banner do
        %(<div>Impersonating</div><div>Maintenance at 9pm</div>).html_safe
      end
      layout.with_body { "Content" }
    end

    assert_selector("[data-app-layout-target='banner']", count: 1)
    assert_selector(".app-layout-banner div", count: 2)
  end

  # The strip is a sibling above the main area, not a child of the content
  # column: that is what lets it span the full width with the sidebar below it.
  def test_the_banner_sits_above_the_main_area_and_outside_the_content_column
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_banner { "Impersonating" }
      layout.with_body { "Content" }
    end

    assert_selector(".app-layout-banner + .app-layout-main")
    assert_no_selector(".app-layout-content .app-layout-banner")
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

  def test_flash_renders_a_toast_container_in_the_bottom_right
    render_inline(Bali::AppLayout::Component.new(flash: { notice: "Saved!" })) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("#toast-notifications.toast.toast-bottom.toast-end")
    assert_selector("#toast-notifications .toast-component.alert-success", text: "Saved!")
  end

  # The wrapper used to be an aria-live region holding alerts that were live
  # regions themselves. A live region inside a live region is not reliably
  # announced by anything, so the roles now live on the toasts alone.
  def test_the_toast_container_is_not_a_live_region
    render_inline(Bali::AppLayout::Component.new(flash: { notice: "Saved!" })) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector("#toast-notifications[aria-live]")
    assert_no_selector("#toast-notifications[role]")
    assert_selector('#toast-notifications [role="status"]')
  end

  # `flash[:warning]` and `flash[:info]` had nowhere to go before: AppLayout read
  # two keys off the hash and dropped the rest.
  def test_flash_keys_beyond_notice_and_alert_are_rendered
    render_inline(Bali::AppLayout::Component.new(flash: { warning: "Careful", info: "Heads up" })) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("#toast-notifications .toast-component.alert-warning", text: "Careful")
    assert_selector("#toast-notifications .toast-component.alert-info", text: "Heads up")
  end

  def test_no_container_without_a_flash
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector("#toast-notifications")
  end

  # `flash[:timedout]` and friends are state, not messages.
  def test_no_container_for_flash_keys_that_are_not_messages
    render_inline(Bali::AppLayout::Component.new(flash: { timedout: true })) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector("#toast-notifications")
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
    assert_selector("main .app-layout-body-container", text: "Content")
    container = page.find(".app-layout-body-container")
    assert_includes container[:class], "p-4"
    assert_includes container[:class], "md:p-6"
  end

  def test_body_container_contained_preset
    render_inline(Bali::AppLayout::Component.new(body_container: :contained, modal: false, drawer: false)) do |layout|
      layout.with_body { "Content" }
    end
    container = page.find(".app-layout-body-container")
    assert_includes container[:class], "max-w-7xl"
    assert_includes container[:class], "mx-auto"
    assert_includes container[:class], "px-4"
    assert_includes container[:class], "md:px-6"
    assert_includes container[:class], "py-4"
  end

  def test_body_container_narrow_preset
    render_inline(Bali::AppLayout::Component.new(body_container: :narrow, modal: false, drawer: false)) do |layout|
      layout.with_body { "Content" }
    end
    container = page.find(".app-layout-body-container")
    assert_includes container[:class], "max-w-xl"
    assert_includes container[:class], "mx-auto"
    assert_includes container[:class], "px-4"
    assert_includes container[:class], "py-4"
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
    assert_includes container[:class], "p-4"
    assert_includes container[:class], "md:p-6"
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

  # --- default mobile topbar tests ---

  def test_auto_renders_default_mobile_topbar_when_fixed_sidebar_and_no_topbar
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: true)) do |layout|
      layout.with_sidebar { "Sidebar" }
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout-topbar--default-mobile.lg\\:hidden")
    assert_selector(
      ".app-layout-topbar--default-mobile " \
      "button[aria-controls='#{Bali::SideMenu::Component::DEFAULT_ID}']"
    )
  end

  def test_default_mobile_topbar_trigger_is_keyboard_operable
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: true)) do |layout|
      layout.with_sidebar { "Sidebar" }
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout-topbar--default-mobile label")
    assert_selector(
      ".app-layout-topbar--default-mobile button[type='button'][aria-expanded='false']"
    )
  end

  def test_default_mobile_topbar_renders_app_name_when_provided
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: true, app_name: "MovieDB")) do |layout|
      layout.with_sidebar { "Sidebar" }
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout-topbar--default-mobile", text: "MovieDB")
  end

  def test_default_mobile_topbar_omits_app_name_when_blank
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: true)) do |layout|
      layout.with_sidebar { "Sidebar" }
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout-topbar--default-mobile span.font-semibold")
  end

  def test_default_mobile_topbar_skipped_when_custom_topbar_provided
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: true, app_name: "Ignored")) do |layout|
      layout.with_sidebar { "Sidebar" }
      layout.with_topbar { "Custom topbar" }
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout-topbar", text: "Custom topbar")
    assert_no_selector(".app-layout-topbar--default-mobile")
  end

  def test_default_mobile_topbar_skipped_without_sidebar
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: true)) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout-topbar--default-mobile")
  end

  def test_default_mobile_topbar_skipped_when_fixed_sidebar_disabled
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: false)) do |layout|
      layout.with_sidebar { "Sidebar" }
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout-topbar--default-mobile")
  end

  def test_main_tag_no_longer_has_p6_hardcoded
    render_inline(Bali::AppLayout::Component.new(modal: false, drawer: false)) do |layout|
      layout.with_body { "Content" }
    end
    main_el = page.find("main")
    refute_includes main_el[:class], "p-6"
  end

  # --- skip link ---

  def test_renders_skip_link_as_the_first_focusable_element
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_navbar { '<a href="/">Home</a>'.html_safe }
      layout.with_body { "Content" }
    end
    focusables = page.all("a[href], button, input, [tabindex]:not([tabindex='-1'])")
    assert_equal "##{Bali::AppLayout::Component::MAIN_ID}", focusables.first[:href]
  end

  def test_skip_link_points_at_the_main_element
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("a.bali-skip-link[href='##{Bali::AppLayout::Component::MAIN_ID}']")
    assert_selector("main##{Bali::AppLayout::Component::MAIN_ID}")
  end

  def test_main_is_programmatically_focusable_so_the_skip_link_moves_focus
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector("main[tabindex='-1']")
  end

  def test_skip_link_can_be_disabled
    render_inline(Bali::AppLayout::Component.new(skip_link: false)) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector("a.bali-skip-link")
  end

  # --- fixed sidebar single source of truth ---

  def test_fixed_sidebar_defaults_to_true_matching_the_side_menu_default
    markup = side_menu_markup
    render_inline(Bali::AppLayout::Component.new) do |layout|
      layout.with_sidebar { markup }
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout--has-fixed-sidebar")
    assert_selector(".side-menu-component--fixed")
  end

  def test_raises_when_the_sidebar_slot_disagrees_with_fixed_sidebar
    markup = side_menu_markup(fixed: true)
    error = assert_raises(ArgumentError) do
      render_inline(Bali::AppLayout::Component.new(fixed_sidebar: false)) do |layout|
        layout.with_sidebar { markup }
        layout.with_body { "Content" }
      end
    end
    assert_match(/fixed_sidebar: false/, error.message)
    assert_match(/fixed: true/, error.message)
  end

  def test_does_not_raise_for_a_sidebar_that_is_not_a_bali_side_menu
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: false)) do |layout|
      layout.with_sidebar { '<aside class="my-own-sidebar">Custom</aside>'.html_safe }
      layout.with_body { "Content" }
    end
    assert_selector(".my-own-sidebar")
  end

  def test_inline_sidebar_pairs_with_fixed_sidebar_false
    markup = side_menu_markup(fixed: false)
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: false)) do |layout|
      layout.with_sidebar { markup }
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout--has-fixed-sidebar")
    assert_selector(".side-menu-component--inline")
  end

  def test_viewport_lock_follows_the_effective_fixed_sidebar_not_the_raw_flag
    # `fixed_sidebar: true` with nothing in the slot used to lock the viewport
    # for a sidebar that was never rendered.
    render_inline(Bali::AppLayout::Component.new(fixed_sidebar: true)) do |layout|
      layout.with_body { "Content" }
    end
    assert_no_selector(".app-layout--viewport-locked")
  end

  def test_viewport_lock_can_still_be_forced_without_a_sidebar
    render_inline(Bali::AppLayout::Component.new(viewport_locked: true)) do |layout|
      layout.with_body { "Content" }
    end
    assert_selector(".app-layout--viewport-locked")
  end

  private

  # Real SideMenu markup, so the sync check is exercised against what the
  # component actually emits rather than a hand-written class list.
  def side_menu_markup(**options)
    render_inline(Bali::SideMenu::Component.new(current_path: "/", **options)) do |menu|
      menu.with_list { |list| list.with_item(name: "Dashboard", href: "/") }
    end
    rendered_content
  end
end
