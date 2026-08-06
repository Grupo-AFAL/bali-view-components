# frozen_string_literal: true

require "test_helper"

class BaliGanttComponentTest < ComponentTestCase
  def payload
    {
      groups: [
        { id: 1, name: "Discovery", status: "in_progress",
          starts_on: "2026-01-05", ends_on: "2026-01-16" },
        { id: 2, name: "Design" }
      ],
      items: [
        { id: 10, group_id: 1, name: "Interviews", status: "in_progress",
          starts_on: "2026-01-05", ends_on: "2026-01-16", percent_complete: 40,
          assignee: { id: 7, name: "Ana Luz", initials: "AL" }, href: "/tasks/10" },
        { id: 11, group_id: 1, name: "Summary", parent_id: 10, status: "complete",
          starts_on: "2026-01-12", ends_on: "2026-01-16" },
        { id: 12, group_id: 2, name: "Release", starts_on: "2026-02-06", milestone: true },
        { id: 13, group_id: 2, name: "Unscheduled" }
      ],
      critical_ids: [ 10 ]
    }
  end

  def component(**overrides)
    Bali::Gantt::Component.new(data: payload, **overrides)
  end

  def test_renders_the_static_board
    render_inline(component)

    assert_selector(".bali-gantt[data-gantt-mode='static']")
    assert_selector(".bali-gantt-canvas")
    assert_selector("details.bali-gantt-group", count: 2)
    assert_selector("summary", text: "Discovery")
    assert_selector(".bali-gantt-row", count: 3)
    assert_selector(".bali-gantt-gridline", minimum: 1)
  end

  def test_bars_carry_inline_geometry_and_status_colors
    render_inline(component)

    bar = page.find("a.bali-gantt-bar", match: :first)
    assert_match(/left: 0px/, bar[:style])
    assert_match(/width: 288px/, bar[:style]) # 12 days × 24 px/day (auto→day for this 33-day span)
    assert_match(/color-mix\(in oklch, var\(--color-info\) 16%, transparent\)/, bar[:style])
    assert_equal "true", bar["data-critical"]
    assert_selector("a.bali-gantt-bar .bali-gantt-progress")
  end

  def test_group_own_dates_render_a_group_bar
    render_inline(component)

    assert_selector("summary .bali-gantt-group-bar", count: 1)
  end

  def test_milestones_render_as_diamonds_not_bars
    render_inline(component)

    assert_selector(".bali-gantt-milestone", count: 1)
  end

  def test_color_by_none_neutralizes_every_bar
    render_inline(component(color_by: :none))

    page.all(".bali-gantt-bar").each do |bar|
      assert_match(/var\(--color-base-content\) 10%/, bar[:style])
    end
    assert_no_selector(".bali-gantt-swatch")
  end

  def test_legend_lists_only_present_statuses_in_catalog_order
    render_inline(component)

    labels = page.all(".bali-gantt-swatch").map { |swatch| swatch.find(:xpath, "..").text.strip }
    assert_equal [ "In progress", "Complete" ], labels
  end

  def test_custom_status_catalog_drives_colors_and_labels
    render_inline(component(statuses: [
                              { value: "in_progress", label: "En curso", color: "--color-warning" },
                              { value: "complete", label: "Hecho", color: "--color-success" }
                            ]))

    assert_text "En curso"
    bar = page.find("a.bali-gantt-bar", match: :first)
    assert_match(/var\(--color-warning\)/, bar[:style])
  end

  def test_zoom_links_rewrite_only_the_namespaced_param
    with_request_url "/admin/projects/1?view=timeline&gantt_zoom=day" do
      render_inline(component(zoom: "day"))
    end

    assert_link "Week", href: "/admin/projects/1?gantt_zoom=week&view=timeline"
    assert_selector("a.btn-active", text: "Day")
  end

  def test_zoom_links_can_be_hidden
    render_inline(component(zoom_links: false))

    assert_no_selector(".join")
  end

  def test_truncation_is_announced_never_silent
    render_inline(component(limit: 1))

    assert_selector("[role='status'].alert-warning", text: /1 of 3|1 de 3/)
  end

  def test_undated_items_get_their_own_section
    render_inline(component)

    assert_selector(".bali-gantt-undated", text: "Unscheduled")
    assert_selector(".bali-gantt-undated", text: /No dates/i)
  end

  def test_empty_data_renders_the_empty_state
    render_inline(Bali::Gantt::Component.new(data: { items: [] }))

    assert_selector(".empty-state-component")
    assert_no_selector(".bali-gantt-canvas")
  end

  def test_interactive_mode_is_signed_but_not_available_yet
    error = assert_raises(ArgumentError) do
      Bali::Gantt::Component.new(data: payload, mode: :interactive)
    end

    assert_match(/phases 2-3/, error.message)
  end

  def test_unknown_mode_and_color_by_raise
    assert_raises(ArgumentError) { Bali::Gantt::Component.new(data: payload, mode: :flying) }
    assert_raises(ArgumentError) { Bali::Gantt::Component.new(data: payload, color_by: :phase) }
  end

  def test_accepts_a_prebuilt_data_document
    doc = Bali::Gantt::Data.new(payload)
    render_inline(Bali::Gantt::Component.new(data: doc))

    assert_selector(".bali-gantt-canvas")
  end

  def test_assignee_chip_renders_initials
    render_inline(component)

    assert_selector(".bali-gantt-assignee", text: "AL")
  end
end
