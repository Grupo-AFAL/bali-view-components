# frozen_string_literal: true

require "test_helper"

class BaliListComponentTest < ComponentTestCase
  #

  def test_rendering_renders_with_daisyui_list_class
    render_inline(Bali::List::Component.new) do |c|
    c.with_item do |i|
    i.with_title("Item 1")
    end
    end
    assert_selector('ul.list[role="list"]')
    assert_selector("li.list-row")
  end

  def test_rendering_renders_list_item_with_text_arguments
    render_inline(Bali::List::Component.new) do |c|
    c.with_item do |i|
    i.with_title("Item 1")
    i.with_subtitle("Subtitle 1")
    end
    end
    assert_selector(".font-semibold", text: "Item 1")
    assert_selector(".text-sm", text: "Subtitle 1")
  end

  def test_rendering_renders_list_item_with_block_arguments
    render_inline(Bali::List::Component.new) do |c|
    c.with_item do |i|
    i.with_title { "Item 1" }
    i.with_subtitle { "Subtitle 1" }
    end
    end
    assert_selector(".font-semibold", text: "Item 1")
    assert_selector(".text-sm", text: "Subtitle 1")
  end

  def test_rendering_renders_list_item_actions
    render_inline(Bali::List::Component.new) do |c|
    c.with_item do |i|
    i.with_action do
    c.tag.a("Link 1", href: "/link-1")
    end
    end
    end
    assert_selector('a[href="/link-1"]', text: "Link 1")
  end
  #

  def test_borderless_option_renders_with_border_by_default
    render_inline(Bali::List::Component.new) do |c|
    c.with_item { |i| i.with_title("Item") }
    end
    assert_selector("ul.list.border.border-base-300")
  end

  def test_borderless_option_removes_border_when_borderless_true
    render_inline(Bali::List::Component.new(borderless: true)) do |c|
    c.with_item { |i| i.with_title("Item") }
    end
    assert_selector("ul.list")
    assert_no_selector("ul.border")
  end
  #

  def test_relaxed_spacing_option_applies_relaxed_spacing_class
    render_inline(Bali::List::Component.new(relaxed_spacing: true)) do |c|
    c.with_item { |i| i.with_title("Item") }
    end
    assert_selector('ul[class*="py-4"]')
  end
  #

  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::List::Component.new(class: "custom-list")) do |c|
    c.with_item { |i| i.with_title("Item") }
    end
    assert_selector("ul.list.custom-list")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::List::Component.new(data: { testid: "my-list" })) do |c|
    c.with_item { |i| i.with_title("Item") }
    end
    assert_selector('ul[data-testid="my-list"]')
  end
  #

  def test_item_options_passthrough_accepts_custom_classes_on_items
    render_inline(Bali::List::Component.new) do |c|
    c.with_item(class: "highlighted") do |i|
    i.with_title("Item")
    end
    end
    assert_selector("li.list-row.highlighted")
  end

  def test_item_options_passthrough_accepts_data_attributes_on_items
    render_inline(Bali::List::Component.new) do |c|
    c.with_item(data: { item: "first" }) do |i|
    i.with_title("Item")
    end
    end
    assert_selector('li[data-item="first"]')
  end
  #

  def test_title_and_subtitle_options_accepts_custom_classes_on_title
    render_inline(Bali::List::Component.new) do |c|
    c.with_item do |i|
    i.with_title("Custom Title", class: "text-primary")
    end
    end
    assert_selector("div.font-semibold.text-primary", text: "Custom Title")
  end

  def test_title_and_subtitle_options_accepts_custom_classes_on_subtitle
    render_inline(Bali::List::Component.new) do |c|
    c.with_item do |i|
    i.with_subtitle("Custom Subtitle", class: "text-info")
    end
    end
    assert_selector("div.text-sm.text-info", text: "Custom Subtitle")
  end
  #

  def test_content_slot_renders_additional_content
    render_inline(Bali::List::Component.new) do |c|
    c.with_item do |i|
    i.with_title("Item")
    "Additional content"
    end
    end
    assert_text("Additional content")
    assert_selector(".list-col-grow")
  end
  #

  def test_constants_has_base_classes_constant
    assert_equal("list", Bali::List::Component::BASE_CLASSES)
  end

  def test_constants_has_bordered_classes_constant
    assert_equal("border border-base-300 rounded-box", Bali::List::Component::BORDERED_CLASSES)
  end
  #

  def test_item_constants_has_base_classes_constant
    assert_equal("list-row", Bali::List::Item::Component::BASE_CLASSES)
  end

  def test_item_constants_has_title_classes_constant
    assert_equal("font-semibold", Bali::List::Item::Component::TITLE_CLASSES)
  end

  def test_item_constants_has_subtitle_classes_constant
    assert_equal("text-sm text-base-content/60", Bali::List::Item::Component::SUBTITLE_CLASSES)
  end
end
