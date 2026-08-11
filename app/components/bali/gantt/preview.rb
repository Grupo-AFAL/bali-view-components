# frozen_string_literal: true

module Bali
  module Gantt
    class Preview < ApplicationViewComponentPreview
      # The data contract is documented in Bali::Gantt::Data: `window` is
      # optional, `groups` nest one level via `parent_id` (like stages and
      # sub-stages), `items` nest one level via `parent_id` (subtasks),
      # `milestone: true` draws a diamond on the item's date, and items without
      # dates are carried through instead of disappearing. `critical_ids` marks
      # the CPM-critical items the island rings and joins with red edges.
      #
      # ONE renderer since #970: the component always mounts the React Flow
      # island, and the skeleton it renders inside the mount is what the visitor
      # sees until React's first commit retires it. Readonly here — no `urls:`,
      # `editable`/`manageable` false — so zoom, collapse, search, filter,
      # color-by and the column selector are pure view state and work with no
      # server behind them.
      #
      # `zoom:` is the one piece of geometry the server still decides: `:auto`
      # resolves against the window so the island opens at the right density
      # instead of rescaling the board the moment it mounts.
      # @param zoom select { choices: [auto, day, week, month] }
      def default(zoom: :auto)
        island(data: sample_data, zoom: zoom)
      end

      # @label Editable (dummy endpoints)
      # The COMPLETE editable island against the dummy's reference schedule
      # endpoints (Admin::Projects::SchedulesController /
      # DependenciesController): drag a bar → PATCH → the server answers the
      # full document and React reconciles; draw an edge between two bars →
      # POST dependency (cycles → 422 → rollback); double-click an edge →
      # DELETE. Requires the seeded project (`bin/rails db:seed`). Edits
      # PERSIST in the dummy database — re-seed to reset.
      #
      # The render call lives in the template because that is where route
      # helpers belong; it is otherwise verbatim what a host writes.
      def editable
        project = Project.order(:id).first
        render_with_template(
          template: "bali/gantt/previews/editable",
          locals: { project: project, gantt: project && ProjectGantt.new(project) }
        )
      end

      # @label Stress (300 items)
      # 300 items over 12 groups from a fixed seed, so every run draws the
      # identical board. What to watch is the swap: the skeleton holds the box,
      # and the island replaces it in one frame — never a white gap, however
      # long the bundle takes.
      def stress
        island(data: large_data)
      end

      # An empty document is the island's to draw: it still mounts, with its
      # toolbar and an empty canvas, rather than the component rendering some
      # other thing in its place. Nothing about the mount changes — same values,
      # same skeleton, `initial_zoom` falls back to the island's own `week`.
      def empty
        island(data: { groups: [], items: [] })
      end

      private

      # Every preview goes through the shared template: the component renders
      # the mount element, the template publishes the metas the loader needs (in
      # a host app that is the layout's job).
      def island(**options)
        render_with_template(
          template: "bali/gantt/previews/component",
          locals: { component: Bali::Gantt::Component.new(**options) }
        )
      end

      # 300 items across 12 groups from a FIXED seed: the board must be
      # identical between one run and the next. Offsets are relative to today so
      # the island's today marker still lands inside the window.
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
            { id: 21, group_id: 2, name: "Island renderer", status: "in_progress",
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
            { id: 42, group_id: 4, name: "Announcement", status: "cancelled" },
            # Sin fechas Y sin grupo — la forma exacta del reporte de #1015: no
            # puede tener barra ni fila, así que solo existe en el conteo del
            # pie y en el drawer "No dates".
            { id: 43, name: "Postmortem review", status: "backlog" }
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
