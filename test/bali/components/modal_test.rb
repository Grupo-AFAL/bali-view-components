# frozen_string_literal: true

require "test_helper"

class BaliModalComponentTest < ComponentTestCase
  def test_basic_rendering_renders_with_modal_open_when_active_is_true
    render_inline(Bali::Modal::Component.new(active: true))
    assert_selector("dialog.modal.modal-open")
  end

  def test_basic_rendering_renders_without_modal_open_when_active_is_false
    render_inline(Bali::Modal::Component.new(active: false))
    assert_selector("dialog.modal")
    assert_no_selector("dialog.modal-open")
  end

  def test_basic_rendering_renders_with_modal_box
    render_inline(Bali::Modal::Component.new)
    assert_selector("div.modal-box")
  end

  def test_basic_rendering_renders_close_button
    render_inline(Bali::Modal::Component.new)
    assert_selector('button[aria-label="Close modal"]')
  end

  def test_basic_rendering_generates_unique_modal_id
    render_inline(Bali::Modal::Component.new)
    assert_selector('dialog.modal[id^="modal-"]')
  end

  def test_basic_rendering_uses_custom_modal_id_when_provided
    render_inline(Bali::Modal::Component.new(id: "custom-modal"))
    assert_selector("dialog.modal#custom-modal")
  end

  # A native `<dialog>` opened with `showModal()`. `role="dialog"` and
  # `aria-modal="true"` are gone because both are implicit on the element, and
  # the second one was a lie in the state a static attribute cannot tell apart:
  # a panel rendered `active:` that no script has opened yet is not modal.
  def test_accessibility_is_a_native_dialog_element
    render_inline(Bali::Modal::Component.new)
    assert_selector("dialog.modal")
    assert_no_selector("dialog.modal[role]")
    assert_no_selector("dialog.modal[aria-modal]")
  end

  # Focus has to land somewhere inside the panel while the skeleton is showing,
  # and at that point the panel holds nothing focusable of its own.
  def test_accessibility_panel_is_focusable_for_the_skeleton_phase
    render_inline(Bali::Modal::Component.new)
    assert_selector('div.modal-box[tabindex="-1"]')
  end

  def test_accessibility_has_aria_labelledby_when_header_slot_is_used
    render_inline(Bali::Modal::Component.new(id: "test-modal")) do |modal|
      modal.with_header(title: "Test")
    end
    assert_selector('dialog.modal[aria-labelledby="test-modal-title"]')
    assert_selector("#test-modal-title", text: "Test")
  end

  # The header slot is the only thing that puts `title_id` on the DOM, so
  # without one the attribute named an element that was never rendered.
  def test_accessibility_does_not_have_aria_labelledby_when_header_slot_is_not_used
    render_inline(Bali::Modal::Component.new(id: "test-modal"))
    assert_no_selector("dialog.modal[aria-labelledby]")
  end

  def test_accessibility_has_aria_describedby_when_body_slot_is_used
    render_inline(Bali::Modal::Component.new(id: "test-modal")) do |modal|
      modal.with_header(title: "Test")
      modal.with_body { "Body content" }
    end
    assert_selector('dialog.modal[aria-describedby="test-modal-description"]')
    assert_selector("#test-modal-description", text: "Body content")
  end

  def test_accessibility_does_not_have_aria_describedby_when_body_slot_is_not_used
    render_inline(Bali::Modal::Component.new) do
      "Just content"
    end
    assert_no_selector("dialog.modal[aria-describedby]")
  end

  def test_content_renders_custom_content
    render_inline(Bali::Modal::Component.new) do
      "<p>Hello World!</p>".html_safe
    end
    assert_selector("p", text: "Hello World!")
  end

  def test_sizes_renders_sm_size
    render_inline(Bali::Modal::Component.new(size: :sm))

    assert_selector("div.modal-box.max-w-sm")
  end

  def test_sizes_renders_md_size
    render_inline(Bali::Modal::Component.new(size: :md))

    assert_selector("div.modal-box.max-w-md")
  end

  def test_sizes_renders_lg_size
    render_inline(Bali::Modal::Component.new(size: :lg))

    assert_selector("div.modal-box.max-w-lg")
  end

  def test_sizes_renders_xl_size
    render_inline(Bali::Modal::Component.new(size: :xl))

    assert_selector("div.modal-box.max-w-xl")
  end

  def test_sizes_renders_full_size
    render_inline(Bali::Modal::Component.new(size: :full))

    assert_selector("div.modal-box.max-w-full")
  end

  def test_custom_classes_merges_custom_classes
    render_inline(Bali::Modal::Component.new(class: "custom-class"))
    assert_selector("dialog.modal-component.custom-class")
  end

  def test_header_slot_renders_header_with_title
    render_inline(Bali::Modal::Component.new(id: "test-modal")) do |modal|
      modal.with_header(title: "My Title")
    end
    assert_selector("h3#test-modal-title", text: "My Title")
  end

  def test_header_slot_renders_header_with_badge
    render_inline(Bali::Modal::Component.new) do |modal|
      modal.with_header(title: "Title", badge: "New", badge_color: :info)
    end
    assert_selector("h3", text: "Title")
    assert_selector(".badge", text: "New")
  end

  def test_header_slot_positions_badge_correctly_in_header
    render_inline(Bali::Modal::Component.new) do |modal|
      modal.with_header(title: "Title", badge: "Badge")
    end
    # Header should have flex layout with justify-between for proper badge positioning
    assert_selector(".flex.items-center.justify-between")
  end

  def test_header_slot_includes_close_button_in_header_by_default
    render_inline(Bali::Modal::Component.new) do |modal|
      modal.with_header(title: "Title")
    end
    assert_selector('button[aria-label="Close modal"]')
  end

  def test_header_slot_can_hide_close_button_in_header
    render_inline(Bali::Modal::Component.new) do |modal|
      modal.with_header(title: "Title", close_button: false)
    end
    # Should not have close button when header has close_button: false
    # Note: the standalone close button is also hidden when header is present
    assert_no_selector('button[aria-label="Close modal"]')
  end

  def test_header_slot_hides_standalone_close_button_when_header_is_present
    render_inline(Bali::Modal::Component.new) do |modal|
      modal.with_header(title: "Title")
    end
    # Should only have one close button (in header), not the absolute positioned one
    assert_selector('button[aria-label="Close modal"]', count: 1)
    assert_no_selector("button.absolute")
  end

  def test_body_slot_renders_body_content
    render_inline(Bali::Modal::Component.new) do |modal|
      modal.with_body { "Body content here" }
    end
    assert_selector(".modal-body", text: "Body content here")
  end

  def test_body_slot_has_description_id_for_accessibility
    render_inline(Bali::Modal::Component.new(id: "test-modal")) do |modal|
      modal.with_body { "Description text" }
    end
    assert_selector("#test-modal-description", text: "Description text")
  end

  def test_actions_slot_renders_actions
    render_inline(Bali::Modal::Component.new) do |modal|
    modal.with_actions do
      '<button class="btn">Save</button>'.html_safe
    end
    end
    assert_selector(".modal-action button.btn", text: "Save")
  end

  def test_actions_slot_has_proper_styling_for_actions
    render_inline(Bali::Modal::Component.new) do |modal|
    modal.with_actions do
      "<button>Action</button>".html_safe
    end
    end
    assert_selector(".modal-action.flex.justify-end")
  end

  def test_combined_slots_renders_all_slots_together
    render_inline(Bali::Modal::Component.new(id: "full-modal")) do |modal|
      modal.with_header(title: "Full Modal", badge: "Important")
      modal.with_body { "Modal body content" }
      modal.with_actions { '<button class="btn">Done</button>'.html_safe }
    end
    assert_selector("#full-modal")
    assert_selector("h3", text: "Full Modal")
    assert_selector(".badge", text: "Important")
    assert_selector(".modal-body", text: "Modal body content")
    assert_selector(".modal-action button.btn", text: "Done")
  end

  def test_confirm_on_close_is_opt_in_and_omitted_by_default
    render_inline(Bali::Modal::Component.new)
    assert_no_selector("[data-modal-confirm-close-message-value]")
  end

  def test_confirm_on_close_adds_confirm_close_message_value_and_self_scoped_controller
    render_inline(Bali::Modal::Component.new(confirm_on_close: true))
    assert_selector("dialog.modal[data-controller='modal'][data-modal-confirm-close-message-value]")
  end

  def test_confirm_on_close_uses_default_message
    render_inline(Bali::Modal::Component.new(confirm_on_close: true))
    modal = page.find("dialog.modal")
    assert_equal("You have unsaved changes. Discard them?", modal["data-modal-confirm-close-message-value"])
  end

  def test_confirm_on_close_honors_custom_message
    render_inline(Bali::Modal::Component.new(confirm_on_close: true, confirm_close_message: "Discard?"))
    assert_selector('[data-modal-confirm-close-message-value="Discard?"]')
  end

  # `shared: false` needs both halves: the value (so a broadcast — an open event naming no
  # modal — never opens this one alongside the shared `#main-modal`, #854) and its own
  # controller instance (under the page-level controller the `template` target is whichever
  # dialog comes first in the DOM, so an event naming THIS modal would be compared against
  # that one's id and dropped).
  def test_shared_false_scopes_its_own_controller_and_opts_out_of_broadcasts
    render_inline(Bali::Modal::Component.new(id: "health-modal", active: false, shared: false))

    assert_selector("dialog#health-modal[data-controller='modal'][data-modal-shared-value='false']")
  end

  def test_shared_defaults_to_true_and_adds_no_attributes
    render_inline(Bali::Modal::Component.new(active: false))

    assert_no_selector("dialog[data-controller]")
    assert_no_selector("dialog[data-modal-shared-value]")
  end

  # An unshared modal only ever opens when an event names it, so without a knowable id
  # nothing can — and the auto-generated fallback id is not knowable.
  def test_shared_false_requires_an_explicit_id
    error = assert_raises(ArgumentError) { Bali::Modal::Component.new(shared: false) }
    assert_match(/requires an explicit `id:`/, error.message)
  end

  def test_shared_false_composes_with_confirm_on_close
    render_inline(Bali::Modal::Component.new(id: "m", shared: false, confirm_on_close: true))

    assert_selector("dialog[data-controller='modal'][data-modal-shared-value='false']" \
                    "[data-modal-confirm-close-message-value]")
  end
end
