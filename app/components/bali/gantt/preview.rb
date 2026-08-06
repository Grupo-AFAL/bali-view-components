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
      # `mode: :interactive` (the React Flow island) raises until phases 2-3
      # (#705/#719) — the option is already part of the signature so host call
      # sites will not need rewriting.
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
      def island
        project = Project.order(:id).first
        render_with_template(
          template: "bali/gantt/previews/island",
          locals: {
            project: project,
            gantt: project && ProjectGantt.new(project),
            i18n: Bali::Gantt::Translations.island
          }
        )
      end

      private

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
