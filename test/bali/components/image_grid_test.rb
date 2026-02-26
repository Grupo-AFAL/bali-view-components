# frozen_string_literal: true

require "test_helper"

class BaliImageGridComponentTest < ComponentTestCase
  def test_grid_configuration_renders_a_4_column_grid_by_default
    render_inline(Bali::ImageGrid::Component.new)
    assert_selector(".grid.grid-cols-4.gap-4")
  end

  def test_grid_configuration_accepts_custom_column_count
    render_inline(Bali::ImageGrid::Component.new(columns: 3))
    assert_selector(".grid.grid-cols-3")
  end

  def test_grid_configuration_accepts_custom_gap
    render_inline(Bali::ImageGrid::Component.new(gap: :lg))
    assert_selector(".gap-6")
  end

  def test_grid_configuration_accepts_gap_as_string
    render_inline(Bali::ImageGrid::Component.new(gap: "sm"))
    assert_selector(".gap-2")
  end

  def test_grid_configuration_passes_through_custom_classes
    render_inline(Bali::ImageGrid::Component.new(class: "custom-class"))
    assert_selector(".grid.custom-class")
  end

  def test_grid_configuration_passes_through_data_attributes
    render_inline(Bali::ImageGrid::Component.new(data: { testid: "image-grid" }))
    assert_selector('[data-testid="image-grid"]')
  end
  Bali::ImageGrid::Component::COLUMNS.each do |count, css_class|
  define_method("test_column_variants_renders_#{count}_column_grid_with_#{css_class}") do
    render_inline(Bali::ImageGrid::Component.new(columns: count))
    assert_selector(".#{css_class}")
  end
  end

  Bali::ImageGrid::Component::GAPS.each do |size, css_class|
  define_method("test_gap_variants_renders_size_gap_with_#{css_class}") do
    render_inline(Bali::ImageGrid::Component.new(gap: size))
    assert_selector(".#{css_class}")
  end
  end

  def test_with_images_renders_image_cards
    render_inline(Bali::ImageGrid::Component.new) do |c|
      c.with_image { '<img src="test.jpg">'.html_safe }
    end
    assert_selector(".card")
    assert_selector('img[src="test.jpg"]')
  end

  def test_with_images_renders_multiple_images
    render_inline(Bali::ImageGrid::Component.new) do |c|
    4.times do
      c.with_image { '<img src="test.jpg">'.html_safe }
    end
    end
    assert_selector(".card", count: 4)
  end

  def test_with_images_applies_default_aspect_ratio
    render_inline(Bali::ImageGrid::Component.new) do |c|
      c.with_image { '<img src="test.jpg">'.html_safe }
    end
    assert_selector("figure.aspect-\\[3\\/2\\]")
  end

  def test_with_images_accepts_custom_aspect_ratio_symbol
    render_inline(Bali::ImageGrid::Component.new) do |c|
      c.with_image(aspect_ratio: :square) { '<img src="test.jpg">'.html_safe }
    end
    assert_selector("figure.aspect-square")
  end

  def test_with_images_accepts_aspect_ratio_as_string
    render_inline(Bali::ImageGrid::Component.new) do |c|
      c.with_image(aspect_ratio: "video") { '<img src="test.jpg">'.html_safe }
    end
    assert_selector("figure.aspect-video")
  end
  def test_image_with_footer_renders_footer_when_provided
    render_inline(Bali::ImageGrid::Component.new) do |c|
    c.with_image do |image|
      image.with_footer { "Caption text" }
      '<img src="test.jpg">'.html_safe
    end
    end
    assert_selector(".card-body", text: "Caption text")
  end

  def test_image_with_footer_does_not_render_footer_element_when_not_provided
    render_inline(Bali::ImageGrid::Component.new) do |c|
      c.with_image { '<img src="test.jpg">'.html_safe }
    end
    assert_no_selector(".card-body")
  end
end

class BaliImageGridImageComponentTest < ComponentTestCase
  def test_aspect_ratios_renders_square_aspect_ratio
    render_inline(Bali::ImageGrid::Image::Component.new(aspect_ratio: :square)) { '<img src="test.jpg">'.html_safe }
    assert_selector("figure.aspect-square")
  end

  def test_aspect_ratios_renders_video_aspect_ratio
    render_inline(Bali::ImageGrid::Image::Component.new(aspect_ratio: :video)) { '<img src="test.jpg">'.html_safe }
    assert_selector("figure.aspect-video")
  end

  def test_aspect_ratios_renders_3_2_aspect_ratio
    render_inline(Bali::ImageGrid::Image::Component.new(aspect_ratio: :"3/2")) { '<img src="test.jpg">'.html_safe }
    assert_selector('figure[class*="aspect-[3/2]"]')
  end

  def test_aspect_ratios_renders_4_3_aspect_ratio
    render_inline(Bali::ImageGrid::Image::Component.new(aspect_ratio: :"4/3")) { '<img src="test.jpg">'.html_safe }
    assert_selector('figure[class*="aspect-[4/3]"]')
  end

  def test_aspect_ratios_renders_4_5_aspect_ratio
    render_inline(Bali::ImageGrid::Image::Component.new(aspect_ratio: :"4/5")) { '<img src="test.jpg">'.html_safe }
    assert_selector('figure[class*="aspect-[4/5]"]')
  end

  def test_aspect_ratios_renders_16_9_aspect_ratio
    render_inline(Bali::ImageGrid::Image::Component.new(aspect_ratio: :"16/9")) { '<img src="test.jpg">'.html_safe }
    assert_selector('figure[class*="aspect-[16/9]"]')
  end

  def test_applies_card_base_classes
    render_inline(Bali::ImageGrid::Image::Component.new) { '<img src="test.jpg">'.html_safe }
    assert_selector(".card.bg-base-100")
  end

  def test_passes_through_custom_classes
    render_inline(Bali::ImageGrid::Image::Component.new(class: "shadow-lg")) { '<img src="test.jpg">'.html_safe }
    assert_selector(".card.shadow-lg")
  end

  def test_passes_through_data_attributes
    render_inline(Bali::ImageGrid::Image::Component.new(data: { image_id: "123" })) do
      '<img src="test.jpg">'.html_safe
    end
    assert_selector('[data-image-id="123"]')
  end

  def test_wraps_content_in_figure_with_overflow_hidden
    render_inline(Bali::ImageGrid::Image::Component.new) { '<img src="test.jpg">'.html_safe }
    assert_selector("figure.overflow-hidden")
  end
end

class BaliImageGridImageFooterComponentTest < ComponentTestCase
  def test_renders_footer_with_card_body_classes
    render_inline(Bali::ImageGrid::Image::FooterComponent.new) { "Footer content" }
    assert_selector(".card-body.p-3", text: "Footer content")
  end

  def test_passes_through_custom_classes
    render_inline(Bali::ImageGrid::Image::FooterComponent.new(class: "bg-primary")) { "Footer" }
    assert_selector(".card-body.bg-primary")
  end
end
