# frozen_string_literal: true

require "test_helper"

class BaliButtonComponentTest < ComponentTestCase
  def test_basic_rendering_renders_a_button_element_with_btn_class
    render_inline(Bali::Button::Component.new) { "Click me" }
    assert_selector("button.btn")
    assert_button("Click me")
  end

  def test_basic_rendering_renders_with_type_button_by_default
    render_inline(Bali::Button::Component.new) { "Click me" }
    assert_selector('button[type="button"]')
  end

  def test_basic_rendering_renders_with_type_submit_when_specified
    render_inline(Bali::Button::Component.new(type: :submit)) { "Submit" }
    assert_selector('button[type="submit"]')
  end

  def test_basic_rendering_renders_with_name_parameter
    render_inline(Bali::Button::Component.new(name: "Click me"))
    assert_button("Click me")
  end

  def test_basic_rendering_prefers_name_over_block_content
    render_inline(Bali::Button::Component.new(name: "Name wins")) { "Block content" }
    assert_button("Name wins")
    assert_no_text("Block content")
  end

  %i[primary secondary accent info success warning error ghost link neutral].each do |variant|
    define_method("test_variants_renders_#{variant}_variant") do
      render_inline(Bali::Button::Component.new(variant: variant)) { "Button" }
      assert_selector("button.btn.btn-#{variant}")
    end
  end

  Bali::ButtonTaxonomy::STYLES.each do |style, css_class|
    define_method("test_styles_renders_#{style}_style") do
      render_inline(Bali::Button::Component.new(style: style)) { "Button" }
      assert_selector("button.btn.#{css_class}")
    end
  end

  def test_styles_compose_with_a_variant_and_a_size
    render_inline(Bali::Button::Component.new(variant: :error, style: :outline, size: :sm))
    assert_selector("button.btn.btn-error.btn-outline.btn-sm")
  end

  def test_variants_rejects_a_style_name_and_names_the_keyword_that_takes_it
    error = assert_raises(ArgumentError) { Bali::Button::Component.new(variant: :outline) }
    assert_match(/variant: :outline is a fill, not a colour/, error.message)
    assert_match(/Use style: :outline/, error.message)
  end

  def test_styles_rejects_a_variant_name_and_names_the_keyword_that_takes_it
    error = assert_raises(ArgumentError) { Bali::Button::Component.new(style: :primary) }
    assert_match(/Use variant: :primary/, error.message)
  end

  def test_variants_rejects_an_unknown_name_and_lists_the_valid_ones
    error = assert_raises(ArgumentError) { Bali::Button::Component.new(variant: :chartreuse) }
    assert_match(/unknown variant :chartreuse/, error.message)
    assert_match(/:primary/, error.message)
  end

  def test_variants_rejects_a_bulma_name_and_names_its_replacement
    error = assert_raises(ArgumentError) { Bali::Button::Component.new(variant: :danger) }
    assert_match(/Bulma name removed in v3/, error.message)
    assert_match(/Use variant: :error/, error.message)
  end

  def test_sizes_renders_xs_size
    render_inline(Bali::Button::Component.new(size: :xs)) { "Button" }

    assert_selector("button.btn.btn-xs")
  end

  def test_sizes_renders_sm_size
    render_inline(Bali::Button::Component.new(size: :sm)) { "Button" }

    assert_selector("button.btn.btn-sm")
  end

  def test_sizes_renders_lg_size
    render_inline(Bali::Button::Component.new(size: :lg)) { "Button" }

    assert_selector("button.btn.btn-lg")
  end

  def test_sizes_renders_xl_size
    render_inline(Bali::Button::Component.new(size: :xl)) { "Button" }

    assert_selector("button.btn.btn-xl")
  end

  def test_sizes_renders_md_size_without_extra_class
    render_inline(Bali::Button::Component.new(size: :md)) { "Button" }
    assert_selector("button.btn")
    assert_no_selector("button.btn-md")
  end

  def test_disabled_state_renders_with_disabled_attribute
    render_inline(Bali::Button::Component.new(disabled: true)) { "Disabled" }
    assert_selector("button.btn.btn-disabled[disabled]")
  end

  def test_loading_state_renders_with_loading_spinner
    render_inline(Bali::Button::Component.new(loading: true)) { "Loading" }
    assert_selector("button.btn")
    assert_selector("button .loading-spinner")
  end

  # `.loading` on the <button> is the bug this used to assert. In daisyUI 5 the class
  # IS the spinner — `aspect-ratio: 1`, a six-unit width and `background-color:
  # currentColor` masked by the spinner SVG — so it collapsed the button to a square
  # and painted it as the spinner, label and all (#839). The spinner belongs inside.
  def test_loading_state_leaves_the_button_box_alone
    render_inline(Bali::Button::Component.new(loading: true)) { "Loading" }
    assert_no_selector("button.loading")
    assert_selector("button > .loading.loading-spinner")
  end

  # The old `.loading` carried `pointer-events: none`, so a loading button was already
  # unclickable — by accident of the class that was breaking its box. Now it is said
  # out loud, and it also stops the button from being submitted or focused.
  def test_loading_state_disables_the_button_and_says_it_is_busy
    render_inline(Bali::Button::Component.new(loading: true)) { "Loading" }
    assert_selector("button[disabled][aria-busy='true']")
  end

  def test_icons_renders_with_icon_keyword
    render_inline(Bali::Button::Component.new(icon: "plus")) { "Add" }
    assert_selector("button.btn")
    # Icon component should be rendered
  end

  def test_icons_renders_with_icon_slot
    render_inline(Bali::Button::Component.new) do |button|
      button.with_icon("check")
      "Save"
    end
    assert_selector("button.btn")
  end

  def test_icons_renders_with_icon_right_slot
    render_inline(Bali::Button::Component.new) do |button|
      button.with_icon_right("arrow-right")
      "Next"
    end
    assert_selector("button.btn")
  end

  def test_custom_attributes_passes_data_attributes
    render_inline(Bali::Button::Component.new(data: { action: "modal#close" })) { "Close" }
    assert_selector('button.btn[data-action="modal#close"]')
  end

  def test_custom_attributes_merges_custom_classes
    render_inline(Bali::Button::Component.new(class: "w-full")) { "Full Width" }
    assert_selector("button.btn.w-full")
  end

  # Responsive (icon-only on mobile)

  def test_responsive_adds_btn_square_class_with_icon
    render_inline(Bali::Button::Component.new(name: "Add", icon: "plus"))
    assert_selector("button.btn.max-sm\\:btn-square")
  end

  def test_responsive_wraps_name_in_hidden_span
    render_inline(Bali::Button::Component.new(name: "Add", icon: "plus"))
    assert_selector("button span.max-sm\\:hidden", text: "Add")
  end

  def test_responsive_adds_aria_label
    render_inline(Bali::Button::Component.new(name: "Add", icon: "plus"))
    assert_selector('button[aria-label="Add"]')
  end

  def test_responsive_false_renders_normally
    render_inline(Bali::Button::Component.new(name: "Add", icon: "plus", responsive: false))
    assert_no_selector("button.max-sm\\:btn-square")
    assert_no_selector("button span.max-sm\\:hidden")
    assert_no_selector("button[aria-label]")
  end

  def test_responsive_without_icon_does_not_add_btn_square
    render_inline(Bali::Button::Component.new(name: "Add"))
    assert_no_selector("button.max-sm\\:btn-square")
  end
end
