# frozen_string_literal: true

require "test_helper"

class BaliPageHeaderComponentTest < ComponentTestCase
  #

  def test_constants_defines_base_classes
    assert_equal("page-header-component mb-6", Bali::PageHeader::Component::BASE_CLASSES)
  end

  def test_constants_defines_frozen_heading_sizes
    assert(Bali::PageHeader::Component::HEADING_SIZES.frozen?)
    assert_equal("text-4xl", Bali::PageHeader::Component::HEADING_SIZES[:h1])
    assert_equal("text-2xl", Bali::PageHeader::Component::HEADING_SIZES[:h3])
  end

  def test_constants_defines_frozen_alignments
    assert(Bali::PageHeader::Component::ALIGNMENTS.frozen?)
    assert_equal({ top: :start, center: :center, bottom: :end }, Bali::PageHeader::Component::ALIGNMENTS)
  end

  def test_constants_defines_back_button_classes
    assert_includes(Bali::PageHeader::Component::BACK_BUTTON_CLASSES, "btn", "btn-ghost")
  end

  def test_constants_defines_title_classes
    assert_includes(Bali::PageHeader::Component::TITLE_CLASSES, "title", "font-bold")
  end

  def test_constants_defines_subtitle_classes
    assert_includes(Bali::PageHeader::Component::SUBTITLE_CLASSES, "subtitle", "text-base-content/60")
  end
  #

  #

  def test_rendering_with_title_and_subtitle_as_params_renders
    render_inline(Bali::PageHeader::Component.new(title: "Title", subtitle: "Subtitle"))
    assert_selector(".level-left h3.title", text: "Title")
    assert_selector(".level-left h5.subtitle", text: "Subtitle")
  end
  #

  #

  def test_rendering_with_title_and_subtitle_as_slots_when_using_text_param_renders
    render_inline(Bali::PageHeader::Component.new) do |c|
    c.with_title("Title")
    c.with_subtitle("Subtitle")
    "Right content"
    end
    assert_selector(".level-left h3.title", text: "Title")
    assert_selector(".level-left h5.subtitle", text: "Subtitle")
    assert_selector(".level-right", text: "Right content")
  end
  #

  def test_rendering_with_title_and_subtitle_as_slots_when_using_the_tag_param_renders_with_custom_heading_tags
    render_inline(Bali::PageHeader::Component.new) do |c|
    c.with_title("Title", tag: :h2)
    c.with_subtitle("Subtitle", tag: :h4)
    end
    assert_selector(".level-left h2.title", text: "Title")
    assert_selector(".level-left h4.subtitle", text: "Subtitle")
  end
  #

  def test_rendering_with_title_and_subtitle_as_slots_with_custom_classes_renders_with_daisyui_text_classes
    render_inline(Bali::PageHeader::Component.new) do |c|
    c.with_title("Title", class: "text-info")
    c.with_subtitle("Subtitle", class: "text-primary")
    end
    assert_selector(".level-left h3.title.text-info", text: "Title")
    assert_selector(".level-left h5.subtitle.text-primary", text: "Subtitle")
  end
  #

  def test_rendering_with_title_and_subtitle_as_slots_when_using_blocks_renders_custom_content
    render_inline(Bali::PageHeader::Component.new) do |c|
    c.with_title { '<h2 class="title">Title</h2>'.html_safe }
    c.with_subtitle { '<p class="subtitle">Subtitle</p>'.html_safe }
    "Right content"
    end
    assert_selector(".level-left h2.title", text: "Title")
    assert_selector(".level-left p.subtitle", text: "Subtitle")
    assert_selector(".level-right", text: "Right content")
  end
  #

  def test_alignment_passes_top_alignment_to_level_as_start
    render_inline(Bali::PageHeader::Component.new(title: "Title", align: :top))
    assert_selector(".level.items-start")
  end

  def test_alignment_passes_center_alignment_to_level_as_center
    render_inline(Bali::PageHeader::Component.new(title: "Title", align: :center))
    assert_selector(".level.items-center")
  end

  def test_alignment_passes_bottom_alignment_to_level_as_end
    render_inline(Bali::PageHeader::Component.new(title: "Title", align: :bottom))
    assert_selector(".level.items-end")
  end

  def test_alignment_defaults_to_center_alignment
    render_inline(Bali::PageHeader::Component.new(title: "Title"))
    assert_selector(".level.items-center")
  end
  #

  def test_back_button_renders_back_button_when_href_is_provided
    render_inline(Bali::PageHeader::Component.new(title: "Title", back: { href: "/back" }))
    assert_selector('.back-button[href="/back"]')
    assert_selector(".btn.btn-ghost")
  end

  def test_back_button_does_not_render_back_button_when_back_is_nil
    render_inline(Bali::PageHeader::Component.new(title: "Title"))
    assert_no_selector(".back-button")
  end

  def test_back_button_does_not_render_back_button_when_href_is_blank
    render_inline(Bali::PageHeader::Component.new(title: "Title", back: { href: "" }))
    assert_no_selector(".back-button")
  end
  #

  def test_options_passthrough_accepts_custom_classes_via_options
    render_inline(Bali::PageHeader::Component.new(title: "Title", class: "custom-class"))
    assert_selector(".page-header-component.custom-class")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::PageHeader::Component.new(title: "Title", data: { testid: "page-header" }))
    assert_selector('[data-testid="page-header"]')
  end
end
