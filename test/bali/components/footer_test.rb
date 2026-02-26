# frozen_string_literal: true

require "test_helper"

class Bali_Footer_ComponentTest < ComponentTestCase
  #

  def test_rendering_renders_a_footer_element
    render_inline(Bali::Footer::Component.new)
    assert_selector("footer.footer-component")
  end
  def test_rendering_applies_neutral_color_by_default
    render_inline(Bali::Footer::Component.new)
    assert_selector("footer.bg-neutral.text-neutral-content")
  end
  def test_rendering_applies_custom_color
    render_inline(Bali::Footer::Component.new(color: :primary))
    assert_selector("footer.bg-primary.text-primary-content")
  end
  def test_rendering_centers_content_when_center_is_true
    render_inline(Bali::Footer::Component.new(center: true))
    assert_selector(".footer-center")
  end
  #

  def test_brand_slot_renders_brand_with_name_and_description
    render_inline(Bali::Footer::Component.new) do |footer|
    footer.with_brand(name: "ACME", description: "Building the future")
    end
    assert_selector("aside h3", text: "ACME")
    assert_selector("aside p", text: "Building the future")
  end
  def test_brand_slot_renders_brand_with_custom_block
    render_inline(Bali::Footer::Component.new) do |footer|
    footer.with_brand { "Custom brand content" }
    end
    assert_selector("aside", text: "Custom brand content")
  end
  #

  def test_sections_slot_renders_section_with_title
    render_inline(Bali::Footer::Component.new) do |footer|
    footer.with_section(title: "Company") do |section|
    section.with_link(name: "About", href: "/about")
    end
    end
    assert_selector(".footer-title", text: "Company")
  end
  def test_sections_slot_renders_section_links
    render_inline(Bali::Footer::Component.new) do |footer|
    footer.with_section(title: "Links") do |section|
    section.with_link(name: "Home", href: "/")
    section.with_link(name: "About", href: "/about")
    end
    end
    assert_selector("a.link", text: "Home")
    assert_selector("a.link", text: "About")
    assert_link("Home", href: "/")
  end
  def test_sections_slot_renders_multiple_sections
    render_inline(Bali::Footer::Component.new) do |footer|
    footer.with_section(title: "Product") do |section|
    section.with_link(name: "Features", href: "#")
    end
    footer.with_section(title: "Company") do |section|
    section.with_link(name: "About", href: "#")
    end
    end
    assert_selector(".footer-title", text: "Product")
    assert_selector(".footer-title", text: "Company")
  end
  #

  def test_bottom_slot_renders_bottom_content
    render_inline(Bali::Footer::Component.new) do |footer|
    footer.with_bottom { "Copyright 2024" }
    end
    assert_selector("div.border-t", text: "Copyright 2024")
  end
  #

  def test_options_passthrough_accepts_custom_classes
    render_inline(Bali::Footer::Component.new(class: "custom-footer"))
    assert_selector("footer.footer-component.custom-footer")
  end
  def test_options_passthrough_accepts_id_attribute
    render_inline(Bali::Footer::Component.new(id: "main-footer"))
    assert_selector("#main-footer")
  end
end
