# frozen_string_literal: true

require "test_helper"

class BaliClipboardComponentTest < ComponentTestCase
  def setup
    @component = Bali::Clipboard::Component.new
  end

  def test_basic_rendering_renders_clipboard_component_with_inline_flex_layout
    render_inline(@component) do |c|
      c.with_trigger("Copy")
      c.with_source("Click button to copy me!")
    end
    assert_selector("div.clipboard-component.inline-flex")
    assert_selector('div.clipboard-component[data-controller="clipboard"]')
  end

  def test_basic_rendering_renders_trigger_button_with_daisyui_btn_classes
    render_inline(@component) do |c|
      c.with_trigger("Copy")
      c.with_source("Text")
    end
    assert_selector("button.btn.btn-ghost.clipboard-trigger", text: "Copy")
    assert_selector('button[data-clipboard-target="button"]')
    assert_selector('button[data-action="click->clipboard#copy"]')
    assert_selector('button[type="button"]')
  end

  def test_basic_rendering_renders_source_with_appropriate_container_styling
    render_inline(@component) do |c|
      c.with_trigger("Copy")
      c.with_source("Click button to copy me!")
    end
    assert_selector("div.clipboard-source.bg-base-200", text: "Click button to copy me!")
    assert_selector('div[data-clipboard-target="source"]')
  end

  def test_success_content_renders_default_success_content_with_translation
    render_inline(@component) do |c|
      c.with_trigger("Copy")
      c.with_source("Text")
    end
    assert_selector("span.clipboard-success-content.hidden.text-success", text: "Copied!")
    assert_selector('span[data-clipboard-target="successContent"]')
  end

  def test_success_content_renders_custom_success_content_when_provided
    render_inline(@component) do |c|
      c.with_trigger("Copy")
      c.with_source("Text")
      c.with_success_content("Done!")
    end
    assert_selector("span.clipboard-success-content", text: "Done!")
    assert_no_text("Copied!")
  end

  def test_success_content_renders_success_content_with_block
    render_inline(@component) do |c|
      c.with_trigger("Copy")
      c.with_source("Text")
      c.with_success_content { "Custom success" }
    end
    assert_selector("span.clipboard-success-content", text: "Custom success")
  end

  def test_block_content_renders_trigger_with_block_content
    render_inline(@component) do |c|
      c.with_trigger { "Block trigger" }
      c.with_source("Text")
    end
    assert_selector("button.clipboard-trigger", text: "Block trigger")
  end

  def test_block_content_renders_source_with_block_content
    render_inline(@component) do |c|
      c.with_trigger("Copy")
      c.with_source { "Block source" }
    end
    assert_selector("div.clipboard-source", text: "Block source")
  end

  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::Clipboard::Component.new(class: "custom-class")) do |c|
      c.with_trigger("Copy")
      c.with_source("Text")
    end
    assert_selector("div.clipboard-component.custom-class")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::Clipboard::Component.new(data: { testid: "clipboard" })) do |c|
      c.with_trigger("Copy")
      c.with_source("Text")
    end
    assert_selector('div[data-testid="clipboard"]')
  end

  def test_options_passthrough_passes_custom_classes_to_trigger
    render_inline(@component) do |c|
      c.with_trigger("Copy", class: "my-trigger")
      c.with_source("Text")
    end
    assert_selector("button.clipboard-trigger.my-trigger")
  end

  def test_options_passthrough_passes_custom_classes_to_source
    render_inline(@component) do |c|
      c.with_trigger("Copy")
      c.with_source("Text", class: "my-source")
    end
    assert_selector("div.clipboard-source.my-source")
  end

  def test_accessibility_includes_default_aria_label_on_trigger
    render_inline(@component) do |c|
      c.with_trigger("Copy")
      c.with_source("Text")
    end
    assert_selector('button[aria-label="Copy to clipboard"]')
  end

  def test_accessibility_allows_custom_aria_label_on_trigger
    render_inline(@component) do |c|
      c.with_trigger("Copy", "aria-label": "Copy API key")
      c.with_source("abc123")
    end
    assert_selector('button[aria-label="Copy API key"]')
  end

  def test_base_classes_constants_defines_base_classes_on_main_component
    assert_includes(Bali::Clipboard::Component::BASE_CLASSES, "clipboard-component")
    assert_includes(Bali::Clipboard::Component::BASE_CLASSES, "inline-flex")
  end

  def test_base_classes_constants_defines_base_classes_on_source_component
    assert_includes(Bali::Clipboard::Source::Component::BASE_CLASSES, "clipboard-source")
    assert_includes(Bali::Clipboard::Source::Component::BASE_CLASSES, "bg-base-200")
  end

  def test_base_classes_constants_defines_base_classes_on_trigger_component
    assert_includes(Bali::Clipboard::Trigger::Component::BASE_CLASSES, "btn")
    assert_includes(Bali::Clipboard::Trigger::Component::BASE_CLASSES, "clipboard-trigger")
  end

  def test_base_classes_constants_defines_base_classes_on_sucesscontent_component
    assert_includes(Bali::Clipboard::SucessContent::Component::BASE_CLASSES, "hidden")
    assert_includes(Bali::Clipboard::SucessContent::Component::BASE_CLASSES, "text-success")
  end
end
