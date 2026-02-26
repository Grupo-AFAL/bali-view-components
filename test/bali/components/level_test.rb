# frozen_string_literal: true

require "test_helper"

class BaliLevelComponentTest < ComponentTestCase
  def setup
    @component = Bali::Level::Component.new
  end


  def test_renders
    render_inline(@component) do |c|
      c.with_left do |level|
        level.with_item(text: "Left")
      end
      c.with_right do |level|
        level.with_item(text: "Right")
      end
    end
    assert_selector(".level div")
    assert_selector("div.level-item", text: "Left")
    assert_selector("div.level-item", text: "Right")
  end


  def test_with_level_items_renders
    render_inline(@component) do |c|
      c.with_item(text: "Item 1")
      c.with_item { "<h1>Item 2</h1>".html_safe }
    end
    assert_selector(".level div")
    assert_selector("div.level-item", text: "Item 1")
    assert_selector("div.level-item", text: "Item 2")
  end


  def test_alignments_applies_start_alignment
    render_inline(Bali::Level::Component.new(align: :start)) do |c|
      c.with_left { "Left content" }
    end
    assert_selector(".level.items-start")
  end


  def test_alignments_applies_center_alignment_by_default
    render_inline(Bali::Level::Component.new) do |c|
      c.with_left { "Left content" }
    end
    assert_selector(".level.items-center")
  end


  def test_alignments_applies_end_alignment
    render_inline(Bali::Level::Component.new(align: :end)) do |c|
      c.with_left { "Left content" }
    end
    assert_selector(".level.items-end")
  end


  def test_alignments_defaults_to_center_alignment_for_invalid_values
    render_inline(Bali::Level::Component.new(align: :invalid)) do |c|
      c.with_left { "Left content" }
    end
    assert_selector(".level.items-center")
  end


  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::Level::Component.new(class: "custom-class")) do |c|
      c.with_item(text: "Item")
    end
    assert_selector(".level.custom-class")
  end


  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::Level::Component.new(data: { testid: "level-test" })) do |c|
      c.with_item(text: "Item")
    end
    assert_selector('[data-testid="level-test"]')
  end


  def test_side_component_renders_left_side_with_items
    render_inline(@component) do |c|
      c.with_left do |side|
        side.with_item(text: "Left 1")
        side.with_item(text: "Left 2")
      end
    end
    assert_selector(".level-left")
    assert_selector(".level-item", text: "Left 1")
    assert_selector(".level-item", text: "Left 2")
  end


  def test_side_component_renders_right_side_with_items
    render_inline(@component) do |c|
      c.with_right do |side|
        side.with_item(text: "Right 1")
      end
    end
    assert_selector(".level-right")
    assert_selector(".level-item", text: "Right 1")
  end


  def test_side_component_accepts_custom_classes_on_side
    render_inline(@component) do |c|
      c.with_left(class: "custom-side") do
        "Content"
      end
    end
    assert_selector(".level-left.custom-side")
  end


  def test_item_component_renders_item_with_text_param
    render_inline(@component) do |c|
      c.with_item(text: "Text param")
    end
    assert_selector(".level-item", text: "Text param")
  end


  def test_item_component_renders_item_with_block_content
    render_inline(@component) do |c|
      c.with_item { "Block content" }
    end
    assert_selector(".level-item", text: "Block content")
  end


  def test_item_component_accepts_custom_classes_on_item
    render_inline(@component) do |c|
      c.with_item(text: "Item", class: "custom-item")
    end
    assert_selector(".level-item.custom-item")
  end
end
