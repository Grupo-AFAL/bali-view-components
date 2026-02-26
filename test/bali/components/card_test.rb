# frozen_string_literal: true

require "test_helper"

class BaliCardComponentTest < ComponentTestCase
  #

  def test_basic_rendering_renders_a_card_with_daisyui_classes
    render_inline(Bali::Card::Component.new) do
    '<div class="content">Content</div>'.html_safe
    end
    assert_selector(".card.bg-base-100")
    assert_selector(".card-body", text: "Content")
  end

  def test_basic_rendering_renders_with_shadow_by_default
    render_inline(Bali::Card::Component.new) do
    "Content"
    end
    assert_selector(".card.shadow-sm")
  end
  #

  def test_image_renders_a_card_with_a_clickable_image
    render_inline(Bali::Card::Component.new) do |c|
    c.with_image(src: "/image.png", href: "/path/to/page")
    end
    assert_selector('figure a[href="/path/to/page"] img[src="/image.png"]')
  end

  def test_image_renders_a_card_with_non_clickable_image
    render_inline(Bali::Card::Component.new) do |c|
    c.with_image(src: "/image.png")
    end
    assert_selector('figure img[src="/image.png"]')
    # Should NOT have double figure tags
    assert_no_selector("figure figure")
  end

  def test_image_renders_image_with_alt_text
    render_inline(Bali::Card::Component.new) do |c|
    c.with_image(src: "/image.png", alt: "Product photo")
    end
    assert_selector('figure img[alt="Product photo"]')
  end

  def test_image_renders_image_with_figure_class
    render_inline(Bali::Card::Component.new) do |c|
    c.with_image(src: "/image.png", figure_class: "px-4 pt-4")
    end
    assert_selector("figure.px-4.pt-4 img")
  end

  def test_image_passes_data_attributes_to_image
    render_inline(Bali::Card::Component.new) do |c|
    c.with_image(src: "/image.png", data: { controller: "lightbox" }, loading: "lazy")
    end
    assert_selector('figure img[data-controller="lightbox"][loading="lazy"]')
  end
  #

  def test_title_slot_renders_a_card_with_title_slot
    render_inline(Bali::Card::Component.new) do |c|
    c.with_title("Card Title")
    "Content"
    end
    assert_selector(".card-body h2.card-title", text: "Card Title")
  end

  def test_title_slot_renders_title_with_custom_class
    render_inline(Bali::Card::Component.new) do |c|
    c.with_title("Title", class: "text-primary")
    end
    assert_selector("h2.card-title.text-primary")
  end
  #

  def test_header_slot_renders_header_with_title_inside_card_body
    render_inline(Bali::Card::Component.new) do |c|
    c.with_header(title: "Header Title")
    "Content"
    end
    assert_selector(".card-body h2.card-title", text: "Header Title")
  end

  def test_header_slot_renders_header_with_subtitle
    render_inline(Bali::Card::Component.new) do |c|
    c.with_header(title: "Main Title", subtitle: "A helpful subtitle")
    end
    assert_selector(".card-body h2.card-title", text: "Main Title")
    assert_selector(".card-body p.text-sm", text: "A helpful subtitle")
  end

  def test_header_slot_renders_header_with_icon
    render_inline(Bali::Card::Component.new) do |c|
    c.with_header(title: "Settings", icon: "cog")
    end
    assert_selector(".card-body .flex.items-center.gap-3")
    assert_selector("h2.card-title", text: "Settings")
  end

  def test_header_slot_renders_header_with_badge
    render_inline(Bali::Card::Component.new) do |c|
    c.with_header(title: "Notifications") do |header|
    header.with_badge { "NEW" }
    end
    end
    assert_selector(".flex.items-center.gap-3.justify-between")
    assert_selector("h2.card-title", text: "Notifications")
    assert_text("NEW")
  end

  def test_header_slot_does_not_add_justify_between_without_badge
    render_inline(Bali::Card::Component.new) do |c|
    c.with_header(title: "No Badge")
    end
    assert_selector(".flex.items-center.gap-3")
    assert_no_selector(".justify-between")
  end

  def test_header_slot_renders_header_with_icon_subtitle_and_badge
    render_inline(Bali::Card::Component.new) do |c|
    c.with_header(title: "Dashboard", subtitle: "Overview of your data", icon: "home") do |header|
    header.with_badge { "Beta" }
    end
    end
    assert_selector(".flex.items-center.gap-3")
    assert_selector("h2.card-title", text: "Dashboard")
    assert_selector("p.text-sm", text: "Overview of your data")
    assert_text("Beta")
  end
  #

  def test_actions_renders_link_actions_with_btn_class
    render_inline(Bali::Card::Component.new) do |c|
    c.with_action(href: "/path", class: "btn-primary") { "Link to path" }
    end
    assert_selector('.card-actions a.btn.btn-primary[href="/path"]', text: "Link to path")
  end

  def test_actions_renders_button_actions_with_btn_class
    render_inline(Bali::Card::Component.new) do |c|
    c.with_action(class: "btn-ghost") { "Click me" }
    end
    assert_selector('.card-actions button.btn.btn-ghost[type="button"]', text: "Click me")
  end

  def test_actions_renders_button_with_data_attributes
    render_inline(Bali::Card::Component.new) do |c|
    c.with_action(data: { turbo: false, action: "click->modal#open" }) { "Open Modal" }
    end
    assert_selector('.card-actions button.btn[data-action="click->modal#open"]')
  end
  #

  def test_custom_image_slot_renders_a_card_with_custom_image_content
    render_inline(Bali::Card::Component.new) do |c|
    c.with_image do
    '<div class="image-content">Custom content in image</div>'.html_safe
    end
    c.with_action(href: "/path") { "Link to path" }
    '<div class="content">Content</div>'.html_safe
    end
    assert_selector("figure .image-content", text: "Custom content in image")
  end
  #

  def test_styles_renders_bordered_style
    render_inline(Bali::Card::Component.new(style: :bordered)) do
    "Content"
    end
    assert_selector(".card.card-border")
  end

  def test_styles_renders_dash_style
    render_inline(Bali::Card::Component.new(style: :dash)) do
    "Content"
    end
    assert_selector(".card.card-dash")
  end
  #

  def test_layouts_renders_side_layout
    render_inline(Bali::Card::Component.new(side: true)) do
    "Content"
    end
    assert_selector(".card.card-side")
  end

  def test_layouts_renders_image_full_layout
    render_inline(Bali::Card::Component.new(image_full: true)) do
    "Content"
    end
    assert_selector(".card.image-full")
  end
  #

  def test_sizes_renders_small_size
    render_inline(Bali::Card::Component.new(size: :sm)) do
    "Content"
    end
    assert_selector(".card.card-sm")
  end

  def test_sizes_renders_large_size
    render_inline(Bali::Card::Component.new(size: :lg)) do
    "Content"
    end
    assert_selector(".card.card-lg")
  end
end
