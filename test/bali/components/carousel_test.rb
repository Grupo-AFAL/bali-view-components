# frozen_string_literal: true

require "test_helper"

class Bali_Carousel_ComponentTest < ComponentTestCase
  def setup
    @options = {}
  end

  def component
    Bali::Carousel::Component.new(**@options)
  end

  def slide_image(text = "Slide")
    "<img src=\"https://placehold.co/320x244?text=#{text}\" />".html_safe
  end

  def render_with_items(component, count: 3)
    render_inline(component) do |c|
      count.times do |i|
        c.with_item { slide_image("Slide#{i + 1}") }
      end
    end
  end

  def test_basic_rendering_renders_the_carousel_structure
    render_with_items(component)
    assert_selector(".glide .glide__track .glide__slides")
  end

  def test_basic_rendering_renders_all_items_as_slides
    render_with_items(component, count: 5)
    assert_selector(".glide__slide", count: 5)
  end

  def test_basic_rendering_does_not_render_without_items
    render_inline(component)
    assert_no_selector(".glide")
  end

  def test_options_applies_start_at_value
    @options[:start_at] = 2
    render_with_items(component)
    assert_selector('div[data-carousel-start-at-value="2"]')
  end

  def test_options_applies_slides_per_view_value
    @options[:slides_per_view] = 3
    render_with_items(component)
    assert_selector('div[data-carousel-per-view-value="3"]')
  end

  def test_options_applies_gap_value
    @options[:gap] = 16
    render_with_items(component)
    assert_selector('div[data-carousel-gap-value="16"]')
  end

  def test_options_applies_focus_at_value
    @options[:focus_at] = :center
    render_with_items(component)
    assert_selector('div[data-carousel-focus-at-value="center"]')
  end

  def test_options_with_autoplay_accepts_symbol_shorthand
    @options[:autoplay] = :medium
    render_with_items(component)
    assert_selector('div[data-carousel-autoplay-value="3000"]')
  end

  def test_options_with_autoplay_accepts_integer_value_directly
    @options[:autoplay] = 5000
    render_with_items(component)
    assert_selector('div[data-carousel-autoplay-value="5000"]')
  end

  def test_options_with_autoplay_disables_autoplay_by_default
    render_with_items(component)
    assert_selector('div[data-carousel-autoplay-value="false"]')
  end

  def test_arrows_slot_renders_arrows_when_requested
    render_inline(component) do |c|
      c.with_arrows
      c.with_item { slide_image }
    end
    assert_selector(".glide__arrows")
    assert_selector("button.glide__arrow--left")
    assert_selector("button.glide__arrow--right")
  end

  def test_arrows_slot_includes_accessibility_labels_on_arrows
    render_inline(component) do |c|
      c.with_arrows
      c.with_item { slide_image }
    end
    assert_selector('button[aria-label="Previous slide"]')
    assert_selector('button[aria-label="Next slide"]')
  end

  def test_arrows_slot_allows_custom_icons
    render_inline(component) do |c|
      c.with_arrows(previous_icon: "chevron-left", next_icon: "chevron-right")
      c.with_item { slide_image }
    end
    assert_selector(".glide__arrow--left svg")
    assert_selector(".glide__arrow--right svg")
  end

  def test_arrows_slot_can_be_hidden
    render_inline(component) do |c|
      c.with_arrows(hidden: true)
      c.with_item { slide_image }
    end
    assert_no_selector(".glide__arrows")
  end

  def test_bullets_slot_renders_bullets_matching_item_count
    render_inline(component) do |c|
      c.with_bullets
      5.times { |i| c.with_item { slide_image(i) } }
    end
    assert_selector(".glide__bullets")
    assert_selector(".glide__bullet", count: 5)
  end

  def test_bullets_slot_includes_accessibility_attributes_on_bullets
    render_inline(component) do |c|
      c.with_bullets
      3.times { |i| c.with_item { slide_image(i) } }
    end
    assert_selector('.glide__bullets[role="tablist"][aria-label="Slide navigation"]')
    assert_selector('button[role="tab"][aria-label="Go to slide 1"]')
    assert_selector('button[role="tab"][aria-label="Go to slide 2"]')
    assert_selector('button[role="tab"][aria-label="Go to slide 3"]')
  end

  def test_bullets_slot_can_be_hidden
    render_inline(component) do |c|
      c.with_bullets(hidden: true)
      c.with_item { slide_image }
    end
    assert_no_selector(".glide__bullets")
  end

  def test_bullets_slot_does_not_render_with_zero_items
    render_inline(component, &:with_bullets)
    assert_no_selector(".glide__bullets")
  end

  def test_constants_has_frozen_defaults
    assert(Bali::Carousel::Component::DEFAULTS.frozen?)
    assert_equal(0, Bali::Carousel::Component::DEFAULTS[:start_at])
    assert_equal(1, Bali::Carousel::Component::DEFAULTS[:slides_per_view])
    assert_equal(0, Bali::Carousel::Component::DEFAULTS[:gap])
    assert_equal(:center, Bali::Carousel::Component::DEFAULTS[:focus_at])
  end

  def test_constants_has_frozen_autoplay_intervals
    assert(Bali::Carousel::Component::AUTOPLAY_INTERVALS.frozen?)
    assert_equal(false, Bali::Carousel::Component::AUTOPLAY_INTERVALS[:disabled])
    assert_equal(5000, Bali::Carousel::Component::AUTOPLAY_INTERVALS[:slow])
    assert_equal(3000, Bali::Carousel::Component::AUTOPLAY_INTERVALS[:medium])
    assert_equal(1500, Bali::Carousel::Component::AUTOPLAY_INTERVALS[:fast])
  end
end

class Bali_Carousel_Arrows_ComponentTest < ComponentTestCase
  def test_has_frozen_icons_constant
    assert(Bali::Carousel::Arrows::Component::ICONS.frozen?)
    assert_equal({ previous: "arrow-left", next: "arrow-right" }, Bali::Carousel::Arrows::Component::ICONS)
  end

  def test_uses_translations_for_accessibility_labels
    I18n.with_locale(:es) do
      render_inline(Bali::Carousel::Arrows::Component.new)
      assert_selector('button[aria-label="Diapositiva anterior"]')
      assert_selector('button[aria-label="Diapositiva siguiente"]')
    end
  end

  def test_accepts_custom_classes
    render_inline(Bali::Carousel::Arrows::Component.new(class: "custom-arrows"))
    assert_selector(".glide__arrows.custom-arrows")
  end

  def test_accepts_data_attributes
    render_inline(Bali::Carousel::Arrows::Component.new(data: { testid: "arrows" }))
    assert_selector('[data-testid="arrows"]')
  end
end

class Bali_Carousel_Bullets_ComponentTest < ComponentTestCase
  def test_uses_translations_for_accessibility_labels
    I18n.with_locale(:es) do
      render_inline(Bali::Carousel::Bullets::Component.new(count: 3))
      assert_selector('.glide__bullets[aria-label="Navegación de diapositivas"]')
      assert_selector('button[aria-label="Ir a diapositiva 1"]')
    end
  end

  def test_accepts_custom_classes
    render_inline(Bali::Carousel::Bullets::Component.new(count: 3, class: "custom-bullets"))
    assert_selector(".glide__bullets.custom-bullets")
  end

  def test_accepts_data_attributes
    render_inline(Bali::Carousel::Bullets::Component.new(count: 3, data: { testid: "bullets" }))
    assert_selector('[data-testid="bullets"]')
  end
end
