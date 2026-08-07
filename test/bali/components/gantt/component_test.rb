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

  # --- the mount ---

  def test_the_component_element_is_the_islands_mount_point
    render_inline(component)

    island = page.find(".bali-gantt")
    assert_equal "gantt", island["data-controller"]
    assert_equal({ "groups" => 2, "items" => 4 },
                 JSON.parse(island["data-gantt-data-value"])
                     .slice("groups", "items").transform_values(&:size))
  end

  # The island is the only renderer (#970), so nothing about the schedule is
  # painted server-side: no board, and no `mode`/`color_by` attributes left over
  # from the renderer that used to choose between them.
  def test_no_board_is_rendered_server_side
    render_inline(component)

    assert_no_selector(".bali-gantt-canvas")
    assert_no_selector(".bali-gantt-row")
    assert_no_selector(".bali-gantt-bar")
    assert_nil page.find(".bali-gantt")["data-gantt-mode"]
    assert_nil page.find(".bali-gantt")["data-gantt-color-by"]
  end

  # --- the skeleton, which is the loading state, not an option ---

  def test_the_skeleton_renders_inside_the_mount
    render_inline(component)

    assert_selector("[data-controller='gantt'] .bali-gantt-skeleton[aria-busy='true'][role='status']")
    assert_selector(".bali-gantt-skeleton .skeleton",
                    count: 2 + (Bali::Gantt::Component::SKELETON_ROWS * 2))
  end

  # A placeholder that leaked the real schedule would be a second renderer by
  # accident — the thing #970 removed.
  def test_the_skeleton_carries_nothing_of_the_real_schedule
    render_inline(component)

    assert_no_text("Interviews")
    assert_no_text("Discovery")
    assert_no_text("Ana Luz")
  end

  # --- the no-JavaScript story ---

  # Without the bundle the skeleton shimmers forever, which reads as "loading"
  # and never resolves. The <noscript> is what stops that from being a lie.
  def test_a_noscript_notice_explains_that_the_island_needs_javascript
    render_inline(component)

    assert_selector("[data-controller='gantt'] noscript", count: 1)
    assert_includes page.find("noscript", visible: :all).native.to_html,
                    "This timeline needs JavaScript"
  end

  def test_the_noscript_notice_is_translated
    I18n.with_locale(:es) do
      render_inline(component)

      assert_includes page.find("noscript", visible: :all).native.to_html,
                      "necesita JavaScript"
    end
  end

  # --- island values ---

  def test_it_serializes_catalogs_i18n_and_authorization
    render_inline(component(editable: true, manageable: false))

    island = page.find(".bali-gantt")
    assert_equal "true", island["data-gantt-editable-value"]
    assert_equal "false", island["data-gantt-manageable-value"]
    catalogs = JSON.parse(island["data-gantt-catalogs-value"])
    assert_equal component.statuses.map { |s| s[:value].to_s },
                 catalogs.fetch("statuses").map { |s| s.fetch("value") }
    assert_equal Bali::Gantt::Translations::KEYS.sort,
                 JSON.parse(island["data-gantt-i18n-value"]).keys.sort
  end

  # The one thing the server still decides about the axis: `:auto` resolved
  # against the window, so the island does not open at its own default (`week`)
  # and rescale the board the moment it mounts.
  def test_it_hands_the_island_the_zoom_it_resolved_from_the_window
    render_inline(component)

    island = page.find(".bali-gantt")
    assert_equal "day", island["data-gantt-initial-zoom-value"] # 33-day window → :auto → :day
    assert_equal "gantt_zoom", island["data-gantt-zoom-param-value"]
  end

  def test_an_explicit_zoom_wins_over_auto
    render_inline(component(zoom: "month", zoom_param: "roadmap_zoom"))

    island = page.find(".bali-gantt")
    assert_equal "month", island["data-gantt-initial-zoom-value"]
    assert_equal "roadmap_zoom", island["data-gantt-zoom-param-value"]
  end

  def test_it_emits_only_the_urls_it_was_given
    render_inline(component(urls: { patch: "/p/1/schedule", dependencies: "/p/1/deps" }))

    island = page.find(".bali-gantt")
    assert_equal "/p/1/schedule", island["data-gantt-patch-url-value"]
    assert_equal "/p/1/deps", island["data-gantt-dependencies-url-value"]
    assert_nil island["data-gantt-schedule-url-value"]
    assert_nil island["data-gantt-new-item-url-value"]
  end

  def test_unknown_url_keys_raise_rather_than_ship_a_silent_viewer
    error = assert_raises(ArgumentError) { component(urls: { pacth: "/typo" }) }

    assert_match(/unknown urls/, error.message)
  end

  def test_the_island_receives_the_whole_document_including_undated_items
    render_inline(component)

    document = JSON.parse(page.find(".bali-gantt")["data-gantt-data-value"])
    assert_equal 4, document.fetch("items").size
    assert_equal [ 10 ], document.fetch("critical_ids")
  end

  def test_a_custom_status_catalog_reaches_the_island
    render_inline(component(statuses: [
                              { value: "in_progress", label: "En curso", color: "--color-warning" }
                            ]))

    catalogs = JSON.parse(page.find(".bali-gantt")["data-gantt-catalogs-value"])
    assert_equal [ { "value" => "in_progress", "label" => "En curso", "color" => "--color-warning" } ],
                 catalogs.fetch("statuses")
  end

  def test_date_locale_defaults_to_the_current_locale
    render_inline(component)
    assert_equal "en", page.find(".bali-gantt")["data-gantt-date-locale-value"]

    render_inline(component(date_locale: "es"))
    assert_equal "es", page.find(".bali-gantt")["data-gantt-date-locale-value"]
  end

  # --- what #970 removed ---

  # A host pinned to beta.6/7 finds out at render time instead of shipping the
  # option as a stray HTML attribute: `**options` would have swallowed every one
  # of these in silence.
  Bali::Gantt::Component::REMOVED_OPTIONS.each_key do |option|
    define_method("test_#{option}_raises_because_the_static_renderer_is_gone") do
      error = assert_raises(ArgumentError) { component(option => :anything) }

      assert_match(/#{option}/, error.message)
      assert_match(/#970/, error.message)
      assert_match(%r{migration-v3-to-v31}, error.message)
    end
  end

  def test_several_removed_options_are_reported_together
    error = assert_raises(ArgumentError) { component(mode: :static, limit: 300) }

    assert_match(/mode/, error.message)
    assert_match(/limit/, error.message)
  end

  # --- the rest of the surface ---

  def test_it_accepts_a_prebuilt_data_document
    render_inline(Bali::Gantt::Component.new(data: Bali::Gantt::Data.new(payload)))

    assert_selector("[data-controller='gantt'][data-gantt-data-value]")
  end

  # An empty schedule is the island's problem to draw, not a reason to render
  # something else: the mount and its values are identical.
  def test_an_empty_document_still_mounts_the_island
    render_inline(Bali::Gantt::Component.new(data: { items: [] }))

    island = page.find(".bali-gantt")
    assert_equal "gantt", island["data-controller"]
    assert_equal "week", island["data-gantt-initial-zoom-value"]
    assert_selector(".bali-gantt-skeleton")
  end

  # `data:` is the Gantt document, so it can never double as a bag of HTML data
  # attributes — everything else passes through to the wrapper untouched.
  def test_options_and_id_land_on_the_wrapper
    render_inline(component(id: "project-1-gantt", class: "mt-6", aria: { label: "Roadmap" }))

    island = page.find("#project-1-gantt")
    assert island[:class].include?("mt-6")
    assert island[:class].include?("bali-gantt")
    assert_equal "Roadmap", island["aria-label"]
    assert_equal "gantt", island["data-controller"]
  end
end
