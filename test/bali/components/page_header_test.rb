# frozen_string_literal: true

require "test_helper"

class BaliPageHeaderComponentTest < ComponentTestCase
  def test_constants_defines_base_classes
    assert_equal("page-header-component mb-4", Bali::PageHeader::Component::BASE_CLASSES)
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

  def test_rendering_with_title_and_subtitle_as_params_renders
    render_inline(Bali::PageHeader::Component.new(title: "Title", subtitle: "Subtitle"))
    assert_selector(".level-left h1.title", text: "Title")
    assert_selector(".level-left p.subtitle", text: "Subtitle")
  end

  # `heading:` names the element of the constructor-provided title, the same thing `tag:`
  # does on the slot. It exists so the page components can lower the level contextually
  # (#1055) without giving up the shared TITLE_CLASSES that passing `title:` buys them.
  def test_heading_param_names_the_element_of_the_constructor_title
    render_inline(Bali::PageHeader::Component.new(title: "Title", heading: :h2))

    assert_selector(".level-left h2.title.text-2xl", text: "Title")
    assert_no_selector("h1")
  end

  def test_rendering_with_title_and_subtitle_as_slots_when_using_text_param_renders
    render_inline(Bali::PageHeader::Component.new) do |c|
      c.with_title("Title")
      c.with_subtitle("Subtitle")
      "Right content"
    end
    assert_selector(".level-left h1.title", text: "Title")
    assert_selector(".level-left p.subtitle", text: "Subtitle")
    assert_selector(".level-right", text: "Right content")
  end

  def test_rendering_with_title_and_subtitle_as_slots_when_using_the_tag_param_renders_with_custom_tags
    render_inline(Bali::PageHeader::Component.new) do |c|
      c.with_title("Title", tag: :h2)
      c.with_subtitle("Subtitle", tag: :h4)
    end
    assert_selector(".level-left h2.title", text: "Title")
    assert_selector(".level-left h4.subtitle", text: "Subtitle")
  end

  # `tag:` names the element; it no longer picks the size. Before v3 it did, so
  # the `h1` default would have jumped to `text-4xl` and the documented
  # `tag: :h2` migration would have shrunk the title instead of leaving it alone.
  def test_rendering_title_size_does_not_follow_the_heading_level
    render_inline(Bali::PageHeader::Component.new) do |c|
      c.with_title("Title", tag: :h4)
    end
    assert_selector(".level-left h4.title.text-2xl", text: "Title")
    assert_no_selector(".level-left h4.title.text-xl")
  end

  def test_rendering_with_title_and_subtitle_as_slots_with_custom_classes_renders_with_daisyui_text_classes
    render_inline(Bali::PageHeader::Component.new) do |c|
      c.with_title("Title", class: "text-info")
      c.with_subtitle("Subtitle", class: "text-primary")
    end
    assert_selector(".level-left h1.title.text-info", text: "Title")
    assert_selector(".level-left p.subtitle.text-primary", text: "Subtitle")
  end

  def test_rendering_with_title_and_subtitle_as_slots_when_using_blocks_renders_custom_content
    render_inline(Bali::PageHeader::Component.new) do |c|
      c.with_title { '<span class="badge">Draft</span> Title'.html_safe }
      c.with_subtitle { '<a href="/x">Subtitle</a>'.html_safe }
      "Right content"
    end
    assert_selector("h1.title span.badge", text: "Draft")
    assert_selector("p.subtitle a", text: "Subtitle")
    assert_selector(".level-right", text: "Right content")
  end

  # #685: every page without a subtitle emitted `<h6 class="subtitle"></h6>`,
  # an empty section in the document outline and an axe violation.
  def test_empty_headings_renders_no_subtitle_element_when_subtitle_is_missing
    render_inline(Bali::PageHeader::Component.new(title: "Title"))
    assert_no_selector(".subtitle")
    assert_empty(empty_headings)
  end

  def test_empty_headings_renders_no_title_element_when_title_is_missing
    render_inline(Bali::PageHeader::Component.new(subtitle: "Subtitle"))
    assert_no_selector(".title")
    assert_selector("p.subtitle", text: "Subtitle")
    assert_empty(empty_headings)
  end

  def test_empty_headings_renders_no_title_block_at_all_when_both_are_missing
    render_inline(Bali::PageHeader::Component.new) { "Right content" }
    assert_no_selector(".page-header-title-block")
    assert_empty(empty_headings)
  end

  def test_empty_headings_ignores_a_blank_slot_title
    render_inline(Bali::PageHeader::Component.new) do |c|
      c.with_title("")
      c.with_subtitle("  ")
    end
    assert_empty(empty_headings)
  end

  def test_heading_level_defaults_to_h1
    render_inline(Bali::PageHeader::Component.new(title: "Title"))
    assert_selector("h1.title", text: "Title")
    assert_equal(1, page.all("h1").size)
  end

  # The subtitle describes the title, it does not open a section of its own.
  def test_heading_level_renders_the_subtitle_as_a_paragraph
    render_inline(Bali::PageHeader::Component.new(title: "Title", subtitle: "Subtitle"))
    assert_selector("p.subtitle", text: "Subtitle")
    assert_no_selector("h6")
  end

  def test_title_tags_render_as_siblings_of_the_heading
    render_inline(Bali::PageHeader::Component.new(title: "The Matrix")) do |c|
      c.with_title_tag { '<span class="badge">Action</span>'.html_safe }
    end
    assert_selector(".page-header-title > h1.title", text: "The Matrix")
    assert_selector(".page-header-title > span.badge", text: "Action")
    assert_no_selector("h1.title .badge")
    assert_equal("The Matrix", page.find("h1.title").text.strip)
  end

  # Unwrapped, two badges cut a 375px title down to 277px of usable width.
  def test_title_tags_row_wraps
    render_inline(Bali::PageHeader::Component.new(title: "The Matrix")) do |c|
      c.with_title_tag { '<span class="badge">Action</span>'.html_safe }
    end
    assert_selector(".page-header-title.flex-wrap")
  end

  def test_title_tags_render_without_a_title
    render_inline(Bali::PageHeader::Component.new) do |c|
      c.with_title_tag { '<span class="badge">Action</span>'.html_safe }
    end
    assert_selector(".page-header-title > span.badge", text: "Action")
    assert_empty(empty_headings)
  end

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

  # An icon-only link with no text is an anonymous node to a screen reader.
  def test_back_button_carries_a_default_accessible_name
    render_inline(Bali::PageHeader::Component.new(title: "Title", back: { href: "/back" }))
    assert_selector(".back-button[aria-label='#{I18n.t('bali_view.page_header.back')}']")
  end

  def test_back_button_accessible_name_is_translated
    I18n.with_locale(:es) do
      render_inline(Bali::PageHeader::Component.new(title: "Title", back: { href: "/back" }))
    end
    assert_selector(".back-button[aria-label='Volver']")
  end

  def test_back_button_accessible_name_can_be_overridden
    render_inline(Bali::PageHeader::Component.new(
      title: "Title", back: { href: "/back", "aria-label": "Back to movies" }
    ))
    assert_selector(".back-button[aria-label='Back to movies']")
  end

  # "Label in Name": with a visible label the accessible name has to match it.
  def test_back_button_leaves_a_visible_label_alone
    render_inline(Bali::PageHeader::Component.new(
      title: "Title", back: { href: "/back", name: "Back to movies" }
    ))
    assert_selector(".back-button", text: "Back to movies")
    assert_no_selector(".back-button[aria-label]")
  end

  def test_options_passthrough_accepts_custom_classes_via_options
    render_inline(Bali::PageHeader::Component.new(title: "Title", class: "custom-class"))
    assert_selector(".page-header-component.custom-class")
  end

  def test_options_passthrough_accepts_data_attributes
    render_inline(Bali::PageHeader::Component.new(title: "Title", data: { testid: "page-header" }))
    assert_selector('[data-testid="page-header"]')
  end

  def test_responsive_is_enabled_by_default
    render_inline(Bali::PageHeader::Component.new(title: "Title"))
    level = page.find(".level")
    assert_includes level[:class], "max-sm:gap-3"
    assert_includes level[:class], "max-sm:flex-col"
    assert_includes level[:class], "max-sm:items-stretch"
  end

  def test_responsive_can_be_disabled
    render_inline(Bali::PageHeader::Component.new(title: "Title", responsive: false))
    level = page.find(".level")
    refute_includes level[:class], "max-sm:gap-3"
    refute_includes level[:class], "max-sm:flex-col"
    refute_includes level[:class], "max-sm:items-stretch"
  end

  def test_responsive_stacks_left_and_right_sides_full_width_on_mobile
    render_inline(Bali::PageHeader::Component.new(title: "Title")) do |c|
      c.with_title("Title")
      "Right content"
    end
    assert_selector(".level-left.max-sm\\:w-full")
    assert_selector(".level-right.max-sm\\:w-full")
  end

  # Inline, the back button costs the title its width on every wrapped line:
  # 291px of the 343px available at 375px, three lines instead of two.
  def test_responsive_gives_the_back_button_its_own_row_on_mobile
    render_inline(Bali::PageHeader::Component.new(title: "Title", back: { href: "/back" }))
    left = page.find(".level-left")
    assert_includes left[:class], "max-sm:flex-col"
    assert_includes left[:class], "max-sm:items-start"
  end

  def test_responsive_keeps_the_back_button_inline_when_disabled
    render_inline(Bali::PageHeader::Component.new(
      title: "Title", back: { href: "/back" }, responsive: false
    ))
    refute_includes page.find(".level-left")[:class], "max-sm:flex-col"
  end

  private

  def empty_headings
    page.all("h1,h2,h3,h4,h5,h6", visible: :all).reject { |h| h.text(:all).strip.present? }
  end
end
