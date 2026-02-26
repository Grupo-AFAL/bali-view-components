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

  %i[primary secondary accent info success warning error ghost link neutral
     outline].each do |variant|
    define_method("test_variants_renders_#{variant}_variant") do
      render_inline(Bali::Button::Component.new(variant: variant)) { "Button" }
      assert_selector("button.btn.btn-#{variant}")
    end
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
    assert_selector("button.btn.loading")
    assert_selector("button .loading-spinner")
  end

  def test_icons_renders_with_icon_name
    render_inline(Bali::Button::Component.new(icon_name: "plus")) { "Add" }
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
end
