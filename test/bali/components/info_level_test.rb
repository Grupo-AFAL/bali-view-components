# frozen_string_literal: true

require "test_helper"

class BaliInfoLevelComponentTest < ComponentTestCase
  def setup
    @component = Bali::InfoLevel::Component.new
  end


  def render_with_item(component = @component)
    render_inline(component) do |c|
      c.with_item do |ci|
        ci.with_heading("Heading")
        ci.with_title("Title")
      end
    end
  end


  def test_basic_rendering_renders_a_div_container
    render_with_item
    assert_selector("div.info-level-component")
  end


  def test_basic_rendering_renders_with_base_classes
    render_with_item
    assert_selector(".info-level-component.flex.flex-wrap.gap-8")
  end


  def test_basic_rendering_renders_heading_and_title
    render_with_item
    assert_selector(".heading", text: "Heading")
    assert_selector(".title", text: "Title")
  end

  Bali::InfoLevel::Component::ALIGNMENTS.each do |align, css_class|
    define_method("test_alignment_applies_#{align}_alignment") do
      component = Bali::InfoLevel::Component.new(align: align)
      render_with_item(component)
      assert_selector(".info-level-component.#{css_class}")
    end
  end


  def test_defaults_to_center_alignment
    render_with_item
    assert_selector(".info-level-component.justify-center")
  end


  def test_options_passthrough_accepts_custom_classes
    component = Bali::InfoLevel::Component.new(class: "custom-class")
    render_with_item(component)
    assert_selector(".info-level-component.custom-class")
  end


  def test_options_passthrough_accepts_data_attributes
    component = Bali::InfoLevel::Component.new(data: { testid: "info-level" })
    render_with_item(component)
    assert_selector('[data-testid="info-level"]')
  end


  def test_options_passthrough_accepts_id_attribute
    component = Bali::InfoLevel::Component.new(id: "my-info-level")
    render_with_item(component)
    assert_selector("#my-info-level.info-level-component")
  end


  def test_multiple_items_renders_multiple_items
    render_inline(@component) do |c|
      c.with_item do |ci|
        ci.with_heading("Heading 1")
        ci.with_title("Title 1")
      end
      c.with_item do |ci|
        ci.with_heading("Heading 2")
        ci.with_title("Title 2")
      end
    end
    assert_selector(".level-item", count: 2)
    assert_selector(".heading", count: 2)
    assert_selector(".title", count: 2)
  end


  def test_multiple_titles_per_item_renders_multiple_titles
    render_inline(@component) do |c|
      c.with_item do |ci|
        ci.with_heading("Heading")
        ci.with_title("Title 1")
        ci.with_title("Title 2")
      end
    end
    assert_selector(".heading", text: "Heading")
    assert_selector(".title", text: "Title 1")
    assert_selector(".title", text: "Title 2")
  end


  def test_custom_heading_block_renders_custom_heading_content
    render_inline(@component) do |c|
      c.with_item do |ci|
        ci.with_heading { "My custom heading" }
        ci.with_title("Title")
      end
    end
    assert_selector(".heading", text: "My custom heading")
  end


  def test_custom_title_block_renders_custom_title_content
    render_inline(@component) do |c|
      c.with_item do |ci|
        ci.with_heading("Heading")
        ci.with_title { "My custom title" }
      end
    end
    assert_selector(".title", text: "My custom title")
  end
end

class BaliInfoLevelItemComponentTest < ComponentTestCase
  def test_base_classes_renders_with_level_item_and_text_center_classes
    render_inline(Bali::InfoLevel::Item::Component.new) do |c|
      c.with_heading("H")
      c.with_title("T")
    end
    assert_selector(".level-item.text-center")
  end


  def test_heading_slot_renders_heading_with_proper_classes
    render_inline(Bali::InfoLevel::Item::Component.new) do |c|
      c.with_heading("My Heading")
      c.with_title("T")
    end
    assert_selector(".heading.text-xs.uppercase.tracking-wide", text: "My Heading")
  end


  def test_heading_slot_allows_custom_classes_on_heading
    render_inline(Bali::InfoLevel::Item::Component.new) do |c|
      c.with_heading("H", class: "extra-class")
      c.with_title("T")
    end
    assert_selector(".heading.extra-class")
  end


  def test_title_slot_renders_title_with_proper_classes
    render_inline(Bali::InfoLevel::Item::Component.new) do |c|
      c.with_heading("H")
      c.with_title("My Title")
    end
    assert_selector(".title.text-2xl.font-bold", text: "My Title")
  end


  def test_title_slot_allows_custom_classes_on_title
    render_inline(Bali::InfoLevel::Item::Component.new) do |c|
      c.with_heading("H")
      c.with_title("T", class: "extra-class")
    end
    assert_selector(".title.extra-class")
  end


  def test_options_passthrough_accepts_custom_classes_on_item
    render_inline(Bali::InfoLevel::Item::Component.new(class: "custom-item")) do |c|
      c.with_heading("H")
      c.with_title("T")
    end
    assert_selector(".level-item.custom-item")
  end


  def test_options_passthrough_accepts_data_attributes_on_item
    render_inline(Bali::InfoLevel::Item::Component.new(data: { testid: "item" })) do |c|
      c.with_heading("H")
      c.with_title("T")
    end
    assert_selector('[data-testid="item"]')
  end
end
