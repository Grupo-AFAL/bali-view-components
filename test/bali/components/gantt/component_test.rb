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

  def test_unknown_mode_fallback_and_color_by_raise
    assert_raises(ArgumentError) { Bali::Gantt::Component.new(data: payload, mode: :flying) }
    assert_raises(ArgumentError) { Bali::Gantt::Component.new(data: payload, color_by: :phase) }
    assert_raises(ArgumentError) { Bali::Gantt::Component.new(data: payload, fallback: :spinner) }
  end

  # --- mode: :interactive (#719) ---

  # THE line of the D16 gate. Every other interactive test passes `fallback:`
  # explicitly, so flipping the default to :skeleton is this constant plus this
  # assertion — and the flip stays honest instead of quietly rewriting what a
  # dozen other tests were proving.
  def test_the_default_fallback_is_static
    assert_equal :static, Bali::Gantt::Component::DEFAULT_FALLBACK

    render_inline(component(mode: :interactive))
    assert_selector("[data-controller='gantt'] .bali-gantt-canvas")
  end

  def test_interactive_mounts_the_island_on_the_component_element
    render_inline(component(mode: :interactive))

    island = page.find(".bali-gantt")
    assert_equal "gantt", island["data-controller"]
    assert_equal "interactive", island["data-gantt-mode"]
    assert_equal({ "groups" => 2, "items" => 4 },
                 JSON.parse(island["data-gantt-data-value"])
                     .slice("groups", "items").transform_values(&:size))
  end

  # The promise of the phase: the same board, inside the mount, so React has
  # something to replace instead of a hole.
  #
  # `fallback:` is explicit in every test that proves a MECHANISM, so flipping
  # DEFAULT_FALLBACK never rewrites them. The default itself is pinned once, in
  # test_the_default_fallback_is_static — that pair of lines is the whole flip.
  def test_interactive_renders_the_static_board_inside_the_mount
    render_inline(component(mode: :interactive, fallback: :static))

    assert_selector("[data-controller='gantt'] .bali-gantt-canvas")
    assert_selector("[data-controller='gantt'] .bali-gantt-row", count: 3)
    assert_selector("[data-controller='gantt'] a.bali-gantt-bar")
    assert_no_selector(".bali-gantt-skeleton")
  end

  # Both renderers must open at the same density or the swap rescales every
  # bar under the visitor: the island's initial zoom IS the static's resolved
  # one (`:auto` → :day for this window).
  def test_interactive_hands_the_island_the_zoom_its_fallback_resolved
    render_inline(component(mode: :interactive))

    island = page.find(".bali-gantt")
    assert_equal "day", island["data-gantt-initial-zoom-value"]
    assert_equal island["data-gantt-zoom"], island["data-gantt-initial-zoom-value"]
    assert_equal "gantt_zoom", island["data-gantt-zoom-param-value"]
  end

  def test_interactive_serializes_catalogs_i18n_and_authorization
    render_inline(component(mode: :interactive, editable: true, manageable: false))

    island = page.find(".bali-gantt")
    assert_equal "true", island["data-gantt-editable-value"]
    assert_equal "false", island["data-gantt-manageable-value"]
    # Catalogs default to the same status vocabulary the static legend uses.
    catalogs = JSON.parse(island["data-gantt-catalogs-value"])
    assert_equal component.statuses.map { |s| s[:value].to_s },
                 catalogs.fetch("statuses").map { |s| s.fetch("value") }
    assert_equal Bali::Gantt::Translations::KEYS.sort,
                 JSON.parse(island["data-gantt-i18n-value"]).keys.sort
  end

  def test_interactive_emits_only_the_urls_it_was_given
    render_inline(component(mode: :interactive,
                            urls: { patch: "/p/1/schedule", dependencies: "/p/1/deps" }))

    island = page.find(".bali-gantt")
    assert_equal "/p/1/schedule", island["data-gantt-patch-url-value"]
    assert_equal "/p/1/deps", island["data-gantt-dependencies-url-value"]
    assert_nil island["data-gantt-schedule-url-value"]
    assert_nil island["data-gantt-new-item-url-value"]
  end

  def test_unknown_url_keys_raise_rather_than_ship_a_silent_viewer
    error = assert_raises(ArgumentError) do
      Bali::Gantt::Component.new(data: payload, mode: :interactive, urls: { pacth: "/typo" })
    end

    assert_match(/unknown urls/, error.message)
  end

  # `limit:` caps the ERB the static fallback emits; the island gets the whole
  # schedule and renders it itself.
  def test_the_island_receives_the_uncapped_document
    render_inline(component(mode: :interactive, fallback: :static, limit: 1))

    assert_selector("[data-controller='gantt'] .bali-gantt-row", count: 1)
    assert_equal 4, JSON.parse(page.find(".bali-gantt")["data-gantt-data-value"])
                        .fetch("items").size
  end

  def test_skeleton_fallback_replaces_the_board_and_keeps_the_mount
    render_inline(component(mode: :interactive, fallback: :skeleton))

    assert_equal "gantt", page.find(".bali-gantt")["data-controller"]
    assert_selector("[data-controller='gantt'] .bali-gantt-skeleton[aria-busy='true']")
    assert_selector(".bali-gantt-skeleton .skeleton",
                    count: 2 + (Bali::Gantt::Component::SKELETON_ROWS * 2))
    assert_no_selector(".bali-gantt-canvas")
    # Nothing of the real schedule leaks into the placeholder.
    assert_no_text("Interviews")
  end

  # A host that toggles `mode:` from a policy passes `fallback:` unconditionally;
  # the static renderer ignores it rather than punishing the call site.
  def test_static_mode_ignores_fallback_and_mounts_nothing
    render_inline(component(fallback: :skeleton))

    assert_selector(".bali-gantt-canvas")
    assert_no_selector(".bali-gantt-skeleton")
    assert_nil page.find(".bali-gantt")["data-controller"]
    assert_nil page.find(".bali-gantt")["data-gantt-data-value"]
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
