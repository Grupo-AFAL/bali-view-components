# frozen_string_literal: true

require "test_helper"

class BaliTimelineComponentTest < ComponentTestCase
  def test_base_rendering_renders_a_timeline_with_daisyui_classes
    render_inline(Bali::Timeline::Component.new)
    assert_selector("ul.timeline.timeline-vertical")
  end

  def test_base_rendering_accepts_custom_classes_via_options
    render_inline(Bali::Timeline::Component.new(class: "my-custom-class"))
    assert_selector("ul.timeline.my-custom-class")
  end

  def test_base_rendering_accepts_additional_html_attributes
    render_inline(Bali::Timeline::Component.new(data: { testid: "my-timeline" }))
    assert_selector('ul.timeline[data-testid="my-timeline"]')
  end
  def test_position_variants_renders_left_position_by_default
    render_inline(Bali::Timeline::Component.new)
    assert_selector("ul.timeline.timeline-vertical")
    assert_no_selector("ul.timeline-snap-icon")
  end

  def test_position_variants_renders_center_position_with_timeline_centered_class
    render_inline(Bali::Timeline::Component.new(position: :center))
    assert_selector("ul.timeline.timeline-centered")
  end

  def test_position_variants_renders_right_position_with_snap_icon_modifier
    render_inline(Bali::Timeline::Component.new(position: :right))
    assert_selector("ul.timeline.timeline-snap-icon")
  end

  def test_position_variants_accepts_position_as_string
    render_inline(Bali::Timeline::Component.new(position: "center"))
    assert_selector("ul.timeline.timeline-centered")
  end
  def test_timeline_items_renders_items_with_daisyui_structure
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_tag_item(heading: "January 2022") { "Content" }
    end
    assert_selector("li", count: 1)
    assert_selector(".timeline-middle")
    # Both timeline-start and timeline-end are rendered, CSS controls visibility
    assert_selector(".timeline-start.timeline-box.timeline-content-box")
    assert_selector(".timeline-end.timeline-box.timeline-content-box")
  end

  def test_timeline_items_renders_item_heading_in_both_content_boxes
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_tag_item(heading: "January 2022") { "Content" }
    end
    # Heading appears in both content boxes (CSS hides one based on position)
    assert_selector(".timeline-start p.font-semibold", text: "January 2022")
    assert_selector(".timeline-end p.font-semibold", text: "January 2022")
  end

  def test_timeline_items_renders_item_content_in_both_content_boxes
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_tag_item { "My timeline content" }
    end
    # Content appears in both boxes (CSS hides one based on position)
    assert_selector(".timeline-start", text: "My timeline content")
    assert_selector(".timeline-end", text: "My timeline content")
  end

  def test_timeline_items_renders_items_with_icons
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_tag_item(icon: "check")
    end
    assert_selector(".timeline-middle .icon-component")
  end

  def test_timeline_items_renders_default_circle_icon_when_no_icon_specified
    render_inline(Bali::Timeline::Component.new, &:with_tag_item)
    assert_selector(".timeline-middle .icon-component")
  end

  def test_timeline_items_renders_items_with_color_variants
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_tag_item(color: :success)
    end
    assert_selector(".timeline-middle.text-success")
  end

  def test_timeline_items_renders_colored_connecting_lines
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_tag_item(color: :primary)
    end
    assert_selector("hr.bg-primary", count: 2)
  end
  def test_timeline_headers_renders_headers_with_daisyui_badge
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_tag_header(text: "Start")
    end
    assert_selector("li", count: 1)
    assert_selector(".timeline-middle")
    assert_selector(".badge", text: "Start")
  end

  def test_timeline_headers_renders_headers_with_default_neutral_color
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_tag_header(text: "Start")
    end
    assert_selector(".badge.badge-neutral", text: "Start")
  end

  def test_timeline_headers_renders_headers_with_color_variant
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_tag_header(text: "Important", color: :primary)
    end
    assert_selector(".badge.badge-primary", text: "Important")
  end

  def test_timeline_headers_supports_legacy_tag_class_for_backwards_compatibility
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_tag_header(text: "Legacy", tag_class: "badge-outline badge-secondary")
    end
    assert_selector(".badge.badge-outline.badge-secondary", text: "Legacy")
  end
  def test_multiple_items_renders_multiple_items_and_headers
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_tag_header(text: "Start")
      c.with_tag_item(heading: "Event 1") { "Content 1" }
      c.with_tag_item(heading: "Event 2") { "Content 2" }
      c.with_tag_header(text: "End")
    end
    assert_selector("li", count: 4)
    assert_selector(".badge", count: 2)
    assert_selector(".timeline-end.timeline-box", count: 2)
  end
  def test_constants_defines_base_classes
    assert_equal("timeline timeline-vertical", Bali::Timeline::Component::BASE_CLASSES)
  end

  def test_constants_defines_frozen_positions_hash
    assert(Bali::Timeline::Component::POSITIONS.frozen?)
    assert_equal(%i[left center right].sort, Bali::Timeline::Component::POSITIONS.keys.sort)
  end
end

class BaliTimelineItemComponentTest < ComponentTestCase
  def test_constants_defines_frozen_colors_hash
    assert(Bali::Timeline::Item::Component::COLORS.frozen?)
    assert_includes(Bali::Timeline::Item::Component::COLORS.keys, :default)
    assert_includes(Bali::Timeline::Item::Component::COLORS.keys, :primary)
    assert_includes(Bali::Timeline::Item::Component::COLORS.keys, :success)
    assert_includes(Bali::Timeline::Item::Component::COLORS.keys, :error)
  end

  def test_constants_defines_frozen_line_colors_hash
    assert(Bali::Timeline::Item::Component::LINE_COLORS.frozen?)
    assert_equal("bg-primary", Bali::Timeline::Item::Component::LINE_COLORS[:primary])
  end

  def test_constants_defines_marker_base_classes
    assert_equal("timeline-middle", Bali::Timeline::Item::Component::MARKER_BASE_CLASSES)
  end
end

class BaliTimelineHeaderComponentTest < ComponentTestCase
  def test_constants_defines_frozen_colors_hash
    assert(Bali::Timeline::Header::Component::COLORS.frozen?)
    assert_includes(Bali::Timeline::Header::Component::COLORS.keys, :default)
    assert_includes(Bali::Timeline::Header::Component::COLORS.keys, :primary)
    assert_includes(Bali::Timeline::Header::Component::COLORS.keys, :success)
    assert_includes(Bali::Timeline::Header::Component::COLORS.keys, :error)
    assert_includes(Bali::Timeline::Header::Component::COLORS.keys, :ghost)
    assert_includes(Bali::Timeline::Header::Component::COLORS.keys, :outline)
  end

  def test_constants_defaults_to_badge_neutral
    assert_equal("badge-neutral", Bali::Timeline::Header::Component::COLORS[:default])
  end
end
