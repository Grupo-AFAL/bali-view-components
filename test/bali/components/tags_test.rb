# frozen_string_literal: true

require "test_helper"

class BaliTagsComponentTest < ComponentTestCase
  #

  def test_container_rendering_renders_with_default_gap
    render_inline(Bali::Tags::Component.new) do |c|
    c.with_item(text: "Tag 1")
    c.with_item(text: "Tag 2")
    end
    assert_selector("div.tags-component.flex.flex-wrap.items-center.gap-2")
  end

  def test_container_rendering_renders_with_custom_gap
    render_inline(Bali::Tags::Component.new(gap: :lg)) do |c|
    c.with_item(text: "Tag")
    end
    assert_selector("div.tags-component.gap-4")
  end

  def test_container_rendering_renders_with_no_gap
    render_inline(Bali::Tags::Component.new(gap: :none)) do |c|
    c.with_item(text: "Tag")
    end
    assert_selector("div.tags-component.gap-0")
  end

  def test_container_rendering_does_not_render_when_empty
    render_inline(Bali::Tags::Component.new)
    assert_no_selector("div.tags-component")
  end

  def test_container_rendering_passes_through_custom_classes
    render_inline(Bali::Tags::Component.new(class: "my-custom-class")) do |c|
    c.with_item(text: "Tag")
    end
    assert_selector("div.tags-component.my-custom-class")
  end

  def test_container_rendering_passes_through_data_attributes
    render_inline(Bali::Tags::Component.new(data: { testid: "tags" })) do |c|
    c.with_item(text: "Tag")
    end
    assert_selector('div.tags-component[data-testid="tags"]')
  end
  #

  def test_tag_items_renders_multiple_tags
    render_inline(Bali::Tags::Component.new) do |c|
    c.with_item(text: "First")
    c.with_item(text: "Second")
    c.with_item(text: "Third")
    end
    assert_selector("div.badge", count: 3)
    assert_text("First")
    assert_text("Second")
    assert_text("Third")
  end

  def test_tag_items_renders_tag_with_color
    render_inline(Bali::Tags::Component.new) do |c|
    c.with_item(text: "Primary", color: :primary)
    end
    assert_selector("div.badge.badge-primary", text: "Primary")
  end

  def test_tag_items_renders_tag_with_size
    render_inline(Bali::Tags::Component.new) do |c|
    c.with_item(text: "Small", size: :sm)
    end
    assert_selector("div.badge.badge-sm", text: "Small")
  end

  def test_tag_items_renders_tag_with_style
    render_inline(Bali::Tags::Component.new) do |c|
    c.with_item(text: "Outline", style: :outline)
    end
    assert_selector("div.badge.badge-outline", text: "Outline")
  end

  def test_tag_items_renders_tag_with_rounded
    render_inline(Bali::Tags::Component.new) do |c|
    c.with_item(text: "Rounded", rounded: true)
    end
    assert_selector("div.badge.rounded-full", text: "Rounded")
  end

  def test_tag_items_renders_link_tags_when_href_provided
    render_inline(Bali::Tags::Component.new) do |c|
    c.with_item(text: "Link Tag", href: "/example")
    end
    assert_selector('a.badge[href="/example"]', text: "Link Tag")
  end

  def test_tag_items_allows_individual_tag_styling
    render_inline(Bali::Tags::Component.new) do |c|
    c.with_item(text: "Primary", color: :primary)
    c.with_item(text: "Error Outline", color: :error, style: :outline)
    c.with_item(text: "Success Rounded", color: :success, rounded: true)
    end
    assert_selector(".badge-primary", text: "Primary")
    assert_selector(".badge-error.badge-outline", text: "Error Outline")
    assert_selector(".badge-success.rounded-full", text: "Success Rounded")
  end
  #

  def test_gaps_constant_has_frozen_hash
    assert(Bali::Tags::Component::GAPS.frozen?)
  end

  def test_gaps_constant_contains_all_gap_options
    assert_equal(%i[none xs sm md lg].sort, Bali::Tags::Component::GAPS.keys.sort)
  end
end
