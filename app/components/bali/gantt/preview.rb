# frozen_string_literal: true

module Bali
  module Gantt
    class Preview < ApplicationViewComponentPreview
      # The data contract is documented in Bali::Gantt::Data: `window` is optional,
      # `groups` nest one level via `parent_id` (like stages/sub-stages), `items`
      # nest one level via `parent_id` (subtasks), `milestone: true` renders a
      # diamond on the item's date, and items without dates land in the "No dates"
      # section instead of disappearing. `critical_ids` marks CPM-critical items.
      #
      # `mode: :interactive` (#719) renders this same board inside the React
      # island's mount element — see the Interactive previews below.
      #
      # The zoom links rewrite only the `gantt_zoom` query param (namespaced, so it
      # can coexist with other controls); inside Lookbook they reload the preview.
      # @param color_by select { choices: [status, none] }
      # @param zoom select { choices: [auto, day, week, month] }
      def default(color_by: :status, zoom: :auto)
        render Bali::Gantt::Component.new(
          data: sample_data,
          color_by: color_by.to_sym,
          zoom: zoom,
          group_label: "Stage"
        )
      end

      # Hosts with their own status vocabulary pass a catalog:
      # `statuses: [{ value:, label:, color: }]` where `color` is a daisyUI
      # variable name ("--color-info") or nil for the neutral gray. The legend
      # shows only the statuses present on screen, in catalog order.
      def custom_status_catalog
        render Bali::Gantt::Component.new(
          data: sample_data,
          statuses: [
            { value: "backlog", label: "Pending", color: nil },
            { value: "in_progress", label: "Cooking", color: "--color-secondary" },
            { value: "complete", label: "Served", color: "--color-success" }
          ]
        )
      end

      # `limit:` caps how many dated items render (default 300) and the cut is
      # ALWAYS announced with the real total — silent caps lie about the plan.
      def truncated
        render Bali::Gantt::Component.new(data: sample_data, limit: 3)
      end

      # No dated items at all: the component renders the shared empty state.
      def empty
        render Bali::Gantt::Component.new(data: { items: [] })
      end

      # @label Island (readonly)
      # The React Flow island (#705) mounted through the full host circuit:
      # `startIslandLoader('gantt')` in the main bundle reads the metas
      # emitted by `react_island_meta_tags`, injects the dedicated
      # gantt-island.js entry, and the GanttController (a
      # ReactIslandController subclass) mounts GanttFlow with values→props.
      # Readonly: no URLs, `editable`/`manageable` false — zoom, collapse,
      # search, filter and color-by are pure view state and work without a
      # server.
      def island_readonly
        render_with_template(
          template: "bali/gantt/previews/island_readonly",
          locals: { data: sample_data, i18n: Bali::Gantt::Translations.island }
        )
      end

      # @label Island (editable, dummy endpoints)
      # The COMPLETE editable island against the dummy's reference schedule
      # endpoints (Admin::Projects::SchedulesController /
      # DependenciesController): drag a bar → PATCH → the server answers the
      # full document and React reconciles; draw an edge between two bars →
      # POST dependency (cycles → 422 → rollback); double-click an edge →
      # DELETE. Requires the seeded project (`bin/rails db:seed`). Edits
      # PERSIST in the dummy database — re-seed to reset.
      #
      # Mounted through `Bali::Gantt::Component` `mode: :interactive` (#719):
      # the same call a host writes, `urls:` and all. The call itself lives in
      # the template because that is where route helpers belong.
      def island
        project = Project.order(:id).first
        render_with_template(
          template: "bali/gantt/previews/island",
          locals: { project: project, gantt: project && ProjectGantt.new(project) }
        )
      end

      # @label Interactive (readonly)
      # `mode: :interactive` with the default `fallback: :static`: the board
      # below is server-rendered INSIDE the island's mount element, with the
      # island's own TimeScale densities and colors, and React replaces it when
      # the bundle lands. Disable JavaScript and the board is what stays — it
      # is the real no-JS rendering, not a placeholder.
      def interactive_readonly
        # `fallback:` explícito A PROPÓSITO, aunque hoy coincida con el default:
        # este preview es la mitad "tablero" de la comparación del gate D16, y
        # si el gate flipa DEFAULT_FALLBACK esta pareja pasaría a comparar
        # esqueleto contra esqueleto con los rótulos al revés.
        interactive(data: sample_data, fallback: :static, group_label: "Stage")
      end

      # @label Interactive (skeleton fallback)
      # The same island with `fallback: :skeleton`: a neutral placeholder
      # instead of the board. This is the escape hatch of D16 — if the swap
      # from a real board ever reads as a flicker, hosts (or Bali's default)
      # move here without touching anything else in the call.
      def interactive_skeleton
        interactive(data: sample_data, fallback: :skeleton, group_label: "Stage")
      end

      # @label Interactive stress (300 items, static fallback)
      # The dataset the D16 gate measures: 300 items over 12 groups, generated
      # from a fixed seed so every run draws the identical board. Watch the
      # moment React takes over — bars should stay where the server put them.
      def interactive_stress
        # `fallback:` explícito por la misma razón que interactive_readonly:
        # es la variante A del A/B del gate y tiene que seguir siendo el
        # tablero pase lo que pase con el default.
        interactive(data: large_data, fallback: :static, group_label: "Workstream")
      end

      # @label Interactive stress (300 items, skeleton fallback)
      # The A/B partner of the preview above: same 300 items, skeleton instead
      # of the board. Compare the two to decide whether Bali's default
      # `fallback:` should stay `:static`.
      def interactive_stress_skeleton
        interactive(data: large_data, fallback: :skeleton, group_label: "Workstream")
      end

      private

      # Every interactive preview goes through the shared template: the
      # component renders the mount element, the template publishes the metas
      # the loader needs (a host layout does that part).
      def interactive(**options)
        render_with_template(
          template: "bali/gantt/previews/interactive",
          locals: {
            component: Bali::Gantt::Component.new(mode: :interactive, **options)
          }
        )
      end

      # 300 items across 12 groups from a FIXED seed: the board must be
      # byte-identical between the `:static` and `:skeleton` runs of the gate,
      # and between one run and the next. Offsets are relative to today so the
      # today marker still lands inside the window.
      def large_data
        rng = Random.new(719)
        today = Date.current
        statuses = %w[backlog in_progress ready_for_review complete cancelled]

        {
          groups: 12.times.map { |i| { id: i + 1, name: "Workstream #{i + 1}" } },
          items: 300.times.map do |i|
            start_offset = rng.rand(-120..150)
            length = rng.rand(2..25)
            { id: 1000 + i, group_id: (i % 12) + 1, name: "Task #{i + 1}",
              status: statuses[rng.rand(statuses.size)],
              starts_on: (today + start_offset).iso8601,
              ends_on: (today + start_offset + length).iso8601,
              percent_complete: rng.rand(0..100) }
          end
        }
      end

      def sample_data
        today = Date.current
        {
          groups: [
            { id: 1, name: "Discovery", status: "complete",
              starts_on: (today - 21).iso8601, ends_on: (today - 8).iso8601 },
            { id: 2, name: "Build", status: "in_progress",
              starts_on: (today - 7).iso8601, ends_on: (today + 21).iso8601 },
            { id: 3, name: "Backend", parent_id: 2 },
            { id: 4, name: "Launch" }
          ],
          items: [
            { id: 10, group_id: 1, name: "Stakeholder interviews", status: "complete",
              starts_on: (today - 21).iso8601, ends_on: (today - 15).iso8601,
              percent_complete: 100,
              assignee: { id: 1, name: "Ana Luz Durán", initials: "AD" } },
            { id: 11, group_id: 1, name: "Findings summary", parent_id: 10,
              status: "complete", starts_on: (today - 16).iso8601,
              ends_on: (today - 15).iso8601, percent_complete: 100 },
            { id: 12, group_id: 1, name: "Scope sign-off", status: "complete",
              starts_on: (today - 14).iso8601, ends_on: (today - 8).iso8601,
              percent_complete: 100 },
            { id: 20, group_id: 2, name: "Component API", status: "in_progress",
              starts_on: (today - 7).iso8601, ends_on: (today + 4).iso8601,
              percent_complete: 60,
              assignee: { id: 2, name: "Bruno Ortega", initials: "BO" } },
            { id: 21, group_id: 2, name: "Static renderer", status: "in_progress",
              starts_on: (today - 2).iso8601, ends_on: (today + 10).iso8601,
              percent_complete: 30, slack_days: 0,
              assignee: { id: 1, name: "Ana Luz Durán", initials: "AD" } },
            { id: 30, group_id: 3, name: "Contract validation", status: "ready_for_review",
              starts_on: (today + 2).iso8601, ends_on: (today + 12).iso8601 },
            { id: 31, group_id: 3, name: "Fixtures", status: "backlog",
              starts_on: (today + 8).iso8601, ends_on: (today + 14).iso8601 },
            { id: 40, group_id: 4, name: "Beta release", milestone: true,
              status: "backlog", starts_on: (today + 21).iso8601 },
            { id: 41, group_id: 4, name: "Docs", status: "backlog" },
            { id: 42, group_id: 4, name: "Announcement", status: "cancelled" }
          ],
          dependencies: [
            { id: 1, predecessor_id: 20, successor_id: 30, dependency_type: "finish_to_start" },
            { id: 2, predecessor_id: 21, successor_id: 40, dependency_type: "finish_to_start" }
          ],
          critical_ids: [ 20, 21, 40 ]
        }
      end
    end
  end
end
