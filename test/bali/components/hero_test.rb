# frozen_string_literal: true

require "test_helper"

class Bali_Hero_ComponentTest < ComponentTestCase
  def setup
    @component = Bali::Hero::Component.new
  end

  def test_basic_rendering_renders_hero_component_with_title_and_subtitle
    render_inline(@component) do |c|
      c.with_title("Titulo")
      c.with_subtitle("Subtitulo")
    end
    assert_selector("div.hero")
    assert_selector("div.hero-content")
    assert_selector("h1.text-5xl.font-bold", text: "Titulo")
    assert_selector("p.py-4", text: "Subtitulo")
  end

  def test_basic_rendering_renders_with_default_background_color
    render_inline(@component)
    assert_selector("div.hero.bg-base-200")
  end

  def test_basic_rendering_renders_actions_slot
    render_inline(@component) do |c|
      c.with_title("Title")
      c.with_actions { "Action Button" }
    end
    assert_selector("div.hero")
    assert_text("Action Button")
  end

  def test_sizes_renders_small_size
    render_inline(Bali::Hero::Component.new(size: :sm))
    assert_selector("div.hero.min-h-48")
  end

  def test_sizes_renders_medium_size
    render_inline(Bali::Hero::Component.new(size: :md))
    assert_selector("div.hero.min-h-80")
  end

  def test_sizes_renders_large_size
    render_inline(Bali::Hero::Component.new(size: :lg))
    assert_selector("div.hero.min-h-screen")
  end

  def test_colors_renders_primary_color
    render_inline(Bali::Hero::Component.new(color: :primary))
    assert_selector("div.hero.bg-primary.text-primary-content")
  end

  def test_colors_renders_secondary_color
    render_inline(Bali::Hero::Component.new(color: :secondary))
    assert_selector("div.hero.bg-secondary.text-secondary-content")
  end

  def test_colors_renders_accent_color
    render_inline(Bali::Hero::Component.new(color: :accent))
    assert_selector("div.hero.bg-accent.text-accent-content")
  end

  def test_colors_renders_neutral_color
    render_inline(Bali::Hero::Component.new(color: :neutral))
    assert_selector("div.hero.bg-neutral.text-neutral-content")
  end

  def test_centered_option_centers_content_by_default
    render_inline(Bali::Hero::Component.new)
    assert_selector("div.hero-content.text-center")
  end

  def test_centered_option_does_not_center_content_when_disabled
    render_inline(Bali::Hero::Component.new(centered: false))
    assert_selector("div.hero-content")
    assert_no_selector("div.hero-content.text-center")
  end

  def test_custom_classes_accepts_custom_classes
    render_inline(Bali::Hero::Component.new(class: "custom-class"))
    assert_selector("div.hero.custom-class")
  end
end
