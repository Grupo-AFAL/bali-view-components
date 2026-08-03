# frozen_string_literal: true

require "test_helper"

class BaliDrawerComponentTest < ComponentTestCase
  def setup
    @options = {}
  end

  def component
    Bali::Drawer::Component.new(**@options)
  end

  def test_basic_rendering_renders_drawer_component
    render_inline(component)
    assert_selector("dialog.drawer-component")
  end

  def test_basic_rendering_renders_drawer_open_class_when_active
    @options.merge!(active: true)
    render_inline(component)
    assert_selector("dialog.drawer-component.drawer-open")
  end

  def test_basic_rendering_renders_with_custom_content
    render_inline(component) do
      "<p>Hello World!</p>".html_safe
    end
    assert_selector("p", text: "Hello World!")
  end

  Bali::Drawer::Component::SIZES.each do |size_key, size_class|
    define_method("test_sizes_renders_#{size_key}_size_with_#{size_class.gsub(/[^a-z0-9_]/, '_')}") do
      @options.merge!(size: size_key)
      render_inline(component)
      assert_selector(".drawer-panel.#{size_class}")
    end
  end

  def test_renders_medium_size_by_default
    render_inline(component)
    assert_selector(".drawer-panel.max-w-lg")
  end

  def test_positions_positions_drawer_on_right_by_default
    render_inline(component)
    assert_selector(".drawer-panel.right-0")
  end

  def test_positions_positions_drawer_on_left
    @options.merge!(position: :left)
    render_inline(component)
    assert_selector(".drawer-panel.left-0")
  end

  def test_positions_uses_correct_transform_for_left_position
    @options.merge!(position: :left)
    render_inline(component)
    assert_selector(".drawer-panel.-translate-x-full")
  end

  def test_positions_uses_correct_transform_for_right_position
    @options.merge!(position: :right)
    render_inline(component)
    assert_selector(".drawer-panel.translate-x-full")
  end

  def test_structure_renders_overlay_for_closing
    render_inline(component)
    assert_selector(".drawer-overlay")
  end

  def test_structure_renders_drawer_panel_with_tailwind_classes
    render_inline(component)
    assert_selector(".drawer-panel.bg-base-100.shadow-2xl")
  end

  # Focus has to land somewhere inside the panel while the skeleton is showing,
  # and at that point the panel holds nothing focusable of its own.
  def test_structure_panel_is_focusable_for_the_skeleton_phase
    render_inline(component)
    assert_selector('.drawer-panel[tabindex="-1"]')
  end

  def test_unique_ids_generates_unique_drawer_id_by_default
    render_inline(component)
    id = page.find("dialog.drawer-component")["id"]
    assert_match(/drawer-[a-f0-9]{8}/, id)
  end

  def test_unique_ids_uses_provided_drawer_id
    @options.merge!(drawer_id: "my-settings-drawer")
    render_inline(component)
    assert_selector("#my-settings-drawer")
  end

  # A `drawer#open` trigger usually names no drawer, so the open event is a broadcast. Every
  # drawer used to answer one, which was fine only while a page carried a single overlay —
  # and the package itself ships a second one in `FeedbackWidget` (#854). A drawer that
  # belongs to one feature opts out and waits to be named.
  def test_broadcast_a_shared_drawer_answers_an_unaddressed_open_by_default
    render_inline(component)
    assert_no_selector("dialog.drawer-component[data-drawer-shared-value]")
  end

  def test_broadcast_an_unshared_drawer_says_so_on_the_controller_element
    @options.merge!(shared: false)
    render_inline(component)
    assert_selector("dialog.drawer-component[data-controller~='drawer'][data-drawer-shared-value='false']")
  end

  # A native `<dialog>` opened with `showModal()`. `role="dialog"` and
  # `aria-modal="true"` are gone because both are implicit on the element, and
  # the second one was a lie in the state a static attribute cannot tell apart:
  # a panel rendered `active:` that no script has opened yet is not modal.
  def test_accessibility_is_a_native_dialog_element
    render_inline(component)
    assert_selector("dialog.drawer-component")
    assert_no_selector("dialog.drawer-component[role]")
    assert_no_selector("dialog.drawer-component[aria-modal]")
  end

  def test_accessibility_connects_aria_labelledby_to_title_when_title_is_provided
    @options.merge!(title: "Settings")
    render_inline(component)
    dialog = page.find("dialog.drawer-component")
    title_id = dialog["aria-labelledby"]
    assert_selector("##{title_id}", text: "Settings")
  end

  def test_accessibility_does_not_add_aria_labelledby_when_no_title_is_provided
    render_inline(component)
    dialog = page.find("dialog.drawer-component")
    assert_nil(dialog["aria-labelledby"])
  end

  def test_accessibility_has_close_button_with_aria_label
    @options.merge!(title: "Settings")
    render_inline(component)
    assert_selector('button[aria-label="Close drawer"]')
  end

  def test_accessibility_overlay_has_aria_hidden_true
    render_inline(component)
    assert_selector('.drawer-overlay[aria-hidden="true"]')
  end

  def test_accessibility_has_escape_key_handling_via_data_action
    render_inline(component)
    dialog = page.find("dialog.drawer-component")
    assert_includes(dialog["data-action"], "keydown.esc->drawer#close")
  end

  def test_title_and_header_renders_title_when_provided
    @options.merge!(title: "My Drawer")
    render_inline(component)
    assert_selector("h2", text: "My Drawer")
  end

  def test_title_and_header_renders_header_slot
    render_inline(component) do |drawer|
      drawer.with_header { "<span>Custom Header</span>".html_safe }
      "<p>Content</p>".html_safe
    end
    assert_selector(".drawer-header span", text: "Custom Header")
  end

  def test_title_and_header_renders_close_button_when_header_or_title_is_present
    @options.merge!(title: "My Drawer")
    render_inline(component)
    assert_selector('.drawer-header button[data-action="drawer#close"]')
  end

  def test_title_and_header_does_not_render_header_section_when_no_title_or_header_slot
    render_inline(component)
    assert_no_selector(".drawer-header")
  end

  def test_footer_slot_renders_footer_slot
    render_inline(component) do |drawer|
      drawer.with_footer { "<button>Save</button>".html_safe }
      "<p>Content</p>".html_safe
    end
    assert_selector(".drawer-footer button", text: "Save")
  end

  def test_footer_slot_does_not_render_footer_section_when_no_footer_slot
    render_inline(component)
    assert_no_selector(".drawer-footer")
  end

  def test_options_passthrough_accepts_custom_classes
    @options.merge!(class: "custom-drawer")
    render_inline(component)
    assert_selector(".drawer-component.custom-drawer")
  end

  def test_options_passthrough_accepts_data_attributes
    @options.merge!(data: { testid: "test-drawer" })
    render_inline(component)
    assert_selector('[data-testid="test-drawer"]')
  end

  def test_options_passthrough_merges_data_attributes_with_defaults
    @options.merge!(data: { custom: "value" })
    render_inline(component)
    dialog = page.find("dialog.drawer-component")
    assert_equal("drawer", dialog["data-controller"])
    assert_equal("value", dialog["data-custom"])
  end

  def test_confirm_close_adds_confirm_close_message_value_by_default
    render_inline(component)
    assert_selector("[data-drawer-confirm-close-message-value]")
  end

  def test_confirm_close_uses_default_message
    render_inline(component)
    dialog = page.find("dialog.drawer-component")
    assert_equal("You have unsaved changes. Discard them?", dialog["data-drawer-confirm-close-message-value"])
  end

  def test_confirm_close_honors_custom_message
    @options.merge!(confirm_close_message: "Descartar cambios?")
    render_inline(component)
    assert_selector('[data-drawer-confirm-close-message-value="Descartar cambios?"]')
  end

  def test_confirm_close_omitted_when_dismissable_without_confirm
    @options.merge!(dismissable_without_confirm: true)
    render_inline(component)
    assert_no_selector("[data-drawer-confirm-close-message-value]")
  end
end
