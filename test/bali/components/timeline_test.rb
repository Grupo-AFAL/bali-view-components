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
      c.with_item(heading: "January 2022") { "Content" }
    end
    assert_selector("li", count: 1)
    assert_selector(".timeline-middle")
    assert_selector(".timeline-start.timeline-box.timeline-content-box", count: 1)
    assert_no_selector(".timeline-end")
  end

  def test_timeline_items_renders_the_heading_exactly_once
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_item(heading: "January 2022") { "Content" }
    end
    assert_selector("p.font-semibold", text: "January 2022", count: 1)
  end

  def test_timeline_items_renders_the_content_exactly_once
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_item { '<span id="event-body">My timeline content</span>'.html_safe }
    end
    assert_selector("#event-body", count: 1)
  end

  def test_timeline_items_emit_one_heading_and_one_content_box_per_item
    render_inline(Bali::Timeline::Component.new) do |c|
      4.times { |i| c.with_item(heading: "Event #{i}") { "Content #{i}" } }
    end
    assert_selector(".timeline-content-box", count: 4)
    assert_selector("p.font-semibold", count: 4)
  end

  def test_timeline_items_leave_no_duplicate_ids_in_the_document
    render_inline(Bali::Timeline::Component.new(position: :center)) do |c|
      3.times { |i| c.with_item(heading: "Event #{i}") { %(<div id="frame-#{i}"></div>).html_safe } }
    end

    ids = page.all("[id]", visible: :all).map { |node| node[:id] }
    assert_equal(ids.uniq, ids)
  end

  def test_timeline_items_renders_items_with_icons
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_item(icon: "check")
    end
    assert_selector(".timeline-middle .icon-component")
  end

  def test_timeline_items_renders_default_circle_icon_when_no_icon_specified
    render_inline(Bali::Timeline::Component.new, &:with_item)
    assert_selector(".timeline-middle .icon-component")
  end

  def test_timeline_items_renders_items_with_color_variants
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_item(color: :success)
    end
    assert_selector(".timeline-middle.text-success")
  end

  def test_timeline_items_renders_colored_connecting_lines
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_item(color: :primary)
    end
    assert_selector("hr.bg-primary", count: 2)
  end

  def test_sides_left_position_places_every_item_on_the_start_side
    render_inline(Bali::Timeline::Component.new(position: :left)) do |c|
      3.times { |i| c.with_item(heading: "Event #{i}") }
    end
    assert_selector(".timeline-content-box.timeline-start", count: 3)
    assert_no_selector(".timeline-content-box.timeline-end")
  end

  def test_sides_right_position_places_every_item_on_the_end_side
    render_inline(Bali::Timeline::Component.new(position: :right)) do |c|
      3.times { |i| c.with_item(heading: "Event #{i}") }
    end
    assert_selector(".timeline-content-box.timeline-end", count: 3)
    assert_no_selector(".timeline-content-box.timeline-start")
  end

  def test_sides_center_position_alternates_sides_across_items
    render_inline(Bali::Timeline::Component.new(position: :center)) do |c|
      4.times { |i| c.with_item(heading: "Event #{i}") }
    end

    assert_equal(%w[start end start end], rendered_sides)
  end

  def test_sides_center_position_alternation_is_not_flipped_by_a_header
    render_inline(Bali::Timeline::Component.new(position: :center)) do |c|
      c.with_item(heading: "Event 0")
      c.with_item(heading: "Event 1")
      c.with_header(text: "Milestone")
      c.with_item(heading: "Event 2")
      c.with_item(heading: "Event 3")
    end

    assert_equal(%w[start end start end], rendered_sides)
  end

  def test_sides_unknown_position_falls_back_to_the_start_side
    render_inline(Bali::Timeline::Component.new(position: :sideways)) do |c|
      c.with_item(heading: "Event")
    end
    assert_selector(".timeline-content-box.timeline-start", count: 1)
  end

  def test_timeline_headers_renders_headers_with_daisyui_badge
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_header(text: "Start")
    end
    assert_selector("li", count: 1)
    assert_selector(".timeline-middle")
    assert_selector(".badge", text: "Start")
  end

  def test_timeline_headers_renders_headers_with_default_neutral_color
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_header(text: "Start")
    end
    assert_selector(".badge.badge-neutral", text: "Start")
  end

  def test_timeline_headers_renders_headers_with_color_variant
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_header(text: "Important", color: :primary)
    end
    assert_selector(".badge.badge-primary", text: "Important")
  end

  def test_timeline_headers_appends_custom_classes_to_the_badge
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_header(text: "Outlined", color: :primary, class: "badge-outline")
    end
    assert_selector(".badge.badge-primary.badge-outline", text: "Outlined")
  end

  def test_timeline_headers_forwards_html_attributes_to_the_badge
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_header(text: "Start", data: { testid: "milestone" })
    end
    assert_selector('.badge[data-testid="milestone"]', text: "Start")
  end

  def test_multiple_items_renders_multiple_items_and_headers
    render_inline(Bali::Timeline::Component.new) do |c|
      c.with_header(text: "Start")
      c.with_item(heading: "Event 1") { "Content 1" }
      c.with_item(heading: "Event 2") { "Content 2" }
      c.with_header(text: "End")
    end
    assert_selector("li", count: 4)
    assert_selector(".badge", count: 2)
    assert_selector(".timeline-content-box", count: 2)
  end

  def test_deprecated_slots_with_tag_item_still_renders_and_warns
    message = capture_bali_deprecation do
      render_inline(Bali::Timeline::Component.new) do |c|
        c.with_tag_item(heading: "January 2022") { "Content" }
      end
    end

    assert_includes(message, "with_tag_item is deprecated")
    assert_selector(".timeline-content-box", count: 1)
    assert_selector("p.font-semibold", text: "January 2022", count: 1)
  end

  def test_deprecated_slots_with_tag_header_still_renders_and_warns
    message = capture_bali_deprecation do
      render_inline(Bali::Timeline::Component.new) do |c|
        c.with_tag_header(text: "Start")
      end
    end

    assert_includes(message, "with_tag_header is deprecated")
    assert_selector(".badge", text: "Start")
  end

  def test_constants_defines_base_classes
    assert_equal("timeline timeline-vertical", Bali::Timeline::Component::BASE_CLASSES)
  end

  def test_constants_defines_frozen_positions_hash
    assert(Bali::Timeline::Component::POSITIONS.frozen?)
    assert_equal(%i[left center right].sort, Bali::Timeline::Component::POSITIONS.keys.sort)
  end

  def test_constants_defines_frozen_sides_hash_without_center
    assert(Bali::Timeline::Component::SIDES.frozen?)
    assert_equal({ left: :start, right: :end }, Bali::Timeline::Component::SIDES)
  end

  private

  # "start" or "end" for each content box, in document order.
  def rendered_sides
    page.all(".timeline-content-box", visible: :all).map do |node|
      node[:class].include?("timeline-start") ? "start" : "end"
    end
  end

  def capture_bali_deprecation(&block)
    captured = []
    previous = Bali.deprecator.behavior
    Bali.deprecator.behavior = ->(message, *) { captured << message }
    block.call
    captured.join("\n")
  ensure
    Bali.deprecator.behavior = previous
  end
end

class BaliTimelineItemComponentTest < ComponentTestCase
  def test_constants_defines_frozen_colors_hash
    assert(Bali::Timeline::Item::Component::COLORS.frozen?)
    assert_equal(Bali::Color::NAMES, Bali::Timeline::Item::Component::COLORS.keys)
  end

  def test_constants_ghost_is_the_default_and_leaves_the_line_uncoloured
    assert_equal(:ghost, Bali::Timeline::Item::Component::DEFAULT_COLOR)
    assert_equal("", Bali::Timeline::Item::Component::LINE_COLORS[:ghost])
  end

  def test_constants_defines_frozen_line_colors_hash
    assert(Bali::Timeline::Item::Component::LINE_COLORS.frozen?)
    assert_equal("bg-primary", Bali::Timeline::Item::Component::LINE_COLORS[:primary])
  end

  def test_constants_defines_marker_base_classes
    assert_equal("timeline-middle", Bali::Timeline::Item::Component::MARKER_BASE_CLASSES)
  end

  def test_constants_defines_frozen_sides_hash
    assert(Bali::Timeline::Item::Component::SIDES.frozen?)
    assert_equal(
      { start: "timeline-start", end: "timeline-end" },
      Bali::Timeline::Item::Component::SIDES
    )
  end

  def test_rendered_standalone_it_defaults_to_the_start_side
    render_inline(Bali::Timeline::Item::Component.new(heading: "Solo"))
    assert_selector(".timeline-start.timeline-box.timeline-content-box", count: 1)
  end
end

class BaliTimelineHeaderComponentTest < ComponentTestCase
  def test_constants_defines_frozen_colors_hash
    assert(Bali::Timeline::Header::Component::COLORS.frozen?)
    assert_equal(Bali::Color::NAMES, Bali::Timeline::Header::Component::COLORS.keys)
  end

  def test_constants_defaults_to_badge_neutral
    assert_equal(:neutral, Bali::Timeline::Header::Component::DEFAULT_COLOR)
    assert_equal("badge-neutral", Bali::Timeline::Header::Component::COLORS[:neutral])
  end

  # `:outline` used to live in COLORS, which made a style look like a colour and
  # left `color:` with two different jobs.
  def test_outline_is_no_longer_a_colour
    error = assert_raises(ArgumentError) do
      Bali::Timeline::Header::Component.new(text: "X", color: :outline)
    end
    assert_includes(error.message, "unknown color :outline")
  end

  def test_deprecated_tag_class_still_sets_the_badge_classes_and_warns
    captured = []
    previous = Bali.deprecator.behavior
    Bali.deprecator.behavior = ->(message, *) { captured << message }

    render_inline(
      Bali::Timeline::Header::Component.new(text: "Legacy", tag_class: "badge-outline badge-secondary")
    )

    assert_includes(captured.join("\n"), "`tag_class:` is deprecated")
    assert_selector(".badge.badge-outline.badge-secondary", text: "Legacy")
  ensure
    Bali.deprecator.behavior = previous
  end
end
