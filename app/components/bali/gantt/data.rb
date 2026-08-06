# frozen_string_literal: true

module Bali
  module Gantt
    # Parses and validates the Gantt data contract (#704, decisions D5/D6).
    #
    # The contract is a plain Hash (symbol or string keys) shaped like:
    #
    #   {
    #     window: { starts_on: "2026-01-01", ends_on: "2026-12-31" },  # optional
    #     groups: [
    #       { id: 1, name: "Discovery",                                 # required
    #         parent_id: nil,          # one level of nesting (sub-groups), like the
    #                                  # real stages tree — a sub-group cannot have
    #                                  # children of its own
    #         position: 0, status: "in_progress",                       # optional
    #         starts_on: "...", ends_on: "...",  # group's own bar (rollup dates)
    #         href: "/projects/1" }                                     # optional
    #     ],
    #     items: [
    #       { id: 10, group_id: 1, name: "Wireframes",                  # id/name required
    #         starts_on: "2026-01-02", ends_on: "2026-01-15",           # ISO8601 dates
    #         parent_id: nil,          # sub-item (subtask); one level, like row_kind
    #         status: "in_progress", priority: "high",                  # optional
    #         milestone: false,        # D6: boolean, rendered as a diamond in :static
    #         percent_complete: 40,    # 0..100
    #         assignee: { id: 7, name: "Ana Luz", initials: "AL" },
    #         slack_days: 3,
    #         href: "/tasks/10" }                                       # optional
    #     ],
    #     dependencies: [
    #       { id: 1, predecessor_id: 10, successor_id: 11,              # ids required
    #         dependency_type: "finish_to_start", lag_days: 0 }
    #     ],
    #     critical_ids: [10, 11]
    #   }
    #
    # Renames against the TDFlow::GanttSerializer this contract generalizes:
    # stages→groups, tasks→items, title→name, stage_id→group_id,
    # parent_stage_id/parent_task_id→parent_id, critical_task_ids→critical_ids.
    # `is_critical` and `row_kind` are derived (critical_ids / parent_id), not fields.
    # `test/bali/components/gantt/serializer_contract_test.rb` keeps the mapping
    # honest against a frozen sample of the real serializer output.
    #
    # Dates follow the portfolio rules: an item with a single date is drawn as a
    # minimum-width bar instead of vanishing into "no dates", and an inverted range
    # is clamped to its start so a negative-width bar cannot render out of place.
    # Structural problems (missing ids, unknown references, bad ISO dates, nesting
    # deeper than one level) raise InvalidError: a typo that silently drops bars
    # would lie about the schedule.
    class Data
      class InvalidError < ArgumentError; end

      ISO_DATE = /\A\d{4}-\d{2}-\d{2}\z/

      Group = Struct.new(:id, :name, :parent_id, :position, :status,
                         :starts_on, :ends_on, :href, keyword_init: true) do
        def dated? = starts_on.present?
      end

      Item = Struct.new(:id, :group_id, :parent_id, :name, :starts_on, :ends_on,
                        :status, :priority, :milestone, :percent_complete,
                        :assignee, :slack_days, :href, keyword_init: true) do
        def milestone? = !!milestone
        def dated? = starts_on.present?
        def sub_item? = parent_id.present?
      end

      Assignee = Struct.new(:id, :name, :initials, keyword_init: true)

      Dependency = Struct.new(:id, :predecessor_id, :successor_id,
                              :dependency_type, :lag_days, keyword_init: true)

      attr_reader :dependencies, :critical_ids, :limit, :dated_total, :undated_total

      # `limit` caps the DATED items (in document order) BEFORE the window is
      # derived, so the time axis is fixed by the bars that actually render —
      # same rule as TDFlow::PortfolioGantt. nil = no cap.
      def initialize(payload, limit: nil)
        raise InvalidError, "Gantt data must be a Hash, got #{payload.class}" unless payload.is_a?(Hash)

        @payload = payload.deep_symbolize_keys
        @limit = limit
        parse!
      end

      # Top-level groups in document order, each followed by its sub-groups —
      # the same nesting rule as the serializer's `ordered_stages`. The host
      # controls the order; `position` is carried through, not sorted on.
      def ordered_groups
        @ordered_groups ||= @groups.reject(&:parent_id).flat_map do |group|
          [ group, *@groups.select { |g| g.parent_id == group.id } ]
        end
      end

      # Dated items of a group: top-level items in document order, each followed
      # by its sub-items. Only items that survived the cap.
      def items_for(group_id)
        rows = @dated_items.select { |item| item.group_id == group_id }
        rows.reject(&:parent_id).flat_map do |item|
          [ item, *rows.select { |i| i.parent_id == item.id } ]
        end
      end

      # Dated items with no group, rendered as an implicit unnamed section.
      def ungrouped_items
        @ungrouped_items ||= items_for(nil)
      end

      def dated_items = @dated_items
      def undated_items = @undated_items

      def critical?(item_or_id)
        id = item_or_id.respond_to?(:id) ? item_or_id.id : item_or_id
        critical_ids.include?(id)
      end

      def truncated? = @limit.present? && dated_total > @limit
      def any? = (dated_total + undated_total).positive?

      # The document as it was handed in — validated, symbolized, UNCAPPED.
      # This is what `mode: :interactive` serializes into the island's `data`
      # value: `limit:` is a static-render concern (it decides how many bars
      # ERB emits), while the island renders the whole schedule and reconciles
      # against the same shape the server returns after a mutation.
      def to_h = @payload

      # Window bounds as Dates. Explicit `window:` wins; otherwise derived from
      # the rendered items plus the groups' own dates (like `build_window`).
      def window_starts_on = window_bounds.first
      def window_ends_on = window_bounds.last

      private

      def parse!
        @groups = Array(@payload[:groups]).map { |raw| build_group(raw) }
        validate_group_tree!

        items = Array(@payload[:items]).map { |raw| build_item(raw) }
        validate_item_tree!(items)

        dated, undated = items.partition(&:dated?)
        @dated_total = dated.size
        @undated_total = undated.size
        @dated_items = @limit ? cap_preserving_parents(dated) : dated
        @undated_items = @limit ? undated.first(@limit) : undated

        @dependencies = Array(@payload[:dependencies]).map { |raw| build_dependency(raw) }
        @critical_ids = Array(@payload[:critical_ids])
      end

      def build_group(raw)
        raise InvalidError, "group requires id and name: #{raw.inspect}" unless raw[:id] && raw[:name]

        starts_on, ends_on = normalize_range(raw[:starts_on], raw[:ends_on], "group #{raw[:id]}")
        Group.new(id: raw[:id], name: raw[:name].to_s, parent_id: raw[:parent_id],
                  position: raw[:position], status: raw[:status]&.to_s,
                  starts_on: starts_on, ends_on: ends_on, href: raw[:href])
      end

      def build_item(raw)
        raise InvalidError, "item requires id and name: #{raw.inspect}" unless raw[:id] && raw[:name]

        if raw[:group_id] && group_ids.exclude?(raw[:group_id])
          raise InvalidError, "item #{raw[:id]} references unknown group #{raw[:group_id]}"
        end

        starts_on, ends_on = normalize_range(raw[:starts_on], raw[:ends_on], "item #{raw[:id]}")
        Item.new(id: raw[:id], group_id: raw[:group_id], parent_id: raw[:parent_id],
                 name: raw[:name].to_s, starts_on: starts_on, ends_on: ends_on,
                 status: raw[:status]&.to_s, priority: raw[:priority]&.to_s,
                 milestone: !!raw[:milestone],
                 percent_complete: normalize_percent(raw[:percent_complete], raw[:id]),
                 assignee: build_assignee(raw[:assignee]),
                 slack_days: raw[:slack_days], href: raw[:href])
      end

      def build_assignee(raw)
        return nil if raw.blank?

        Assignee.new(id: raw[:id], name: raw[:name].to_s, initials: raw[:initials].to_s)
      end

      def build_dependency(raw)
        unless raw[:predecessor_id] && raw[:successor_id]
          raise InvalidError, "dependency requires predecessor_id and successor_id: #{raw.inspect}"
        end

        Dependency.new(id: raw[:id], predecessor_id: raw[:predecessor_id],
                       successor_id: raw[:successor_id],
                       dependency_type: raw[:dependency_type]&.to_s,
                       lag_days: raw[:lag_days] || 0)
      end

      # Portfolio date rules (derive_dates): each end falls back on the other
      # before giving up, and an inverted range clamps to its start.
      def normalize_range(starts_on, ends_on, context)
        starts = parse_date(starts_on, context)
        ends = parse_date(ends_on, context)
        starts ||= ends
        return [ nil, nil ] if starts.nil?

        [ starts, [ ends || starts, starts ].max ]
      end

      def parse_date(value, context)
        return nil if value.blank?
        return value if value.is_a?(Date)

        raise InvalidError, "#{context}: date must be ISO8601 (YYYY-MM-DD), got #{value.inspect}" unless
          value.is_a?(String) && value.match?(ISO_DATE)

        Date.iso8601(value)
      rescue Date::Error
        raise InvalidError, "#{context}: invalid date #{value.inspect}"
      end

      def normalize_percent(value, id)
        return nil if value.blank?

        Integer(value).clamp(0, 100)
      rescue ArgumentError, TypeError
        raise InvalidError, "item #{id}: percent_complete must be a number, got #{value.inspect}"
      end

      def validate_group_tree!
        @groups.each do |group|
          next if group.parent_id.nil?

          parent = @groups.find { |g| g.id == group.parent_id }
          raise InvalidError, "group #{group.id} references unknown parent #{group.parent_id}" if parent.nil?
          raise InvalidError, "group #{group.id}: sub-groups cannot nest further (max 2 levels)" if parent.parent_id
        end
      end

      def validate_item_tree!(items)
        by_id = items.index_by(&:id)
        items.each do |item|
          next if item.parent_id.nil?

          parent = by_id[item.parent_id]
          raise InvalidError, "item #{item.id} references unknown parent #{item.parent_id}" if parent.nil?
          raise InvalidError, "item #{item.id}: sub-items cannot nest further (max 2 levels)" if parent.parent_id
          if parent.group_id != item.group_id
            raise InvalidError, "item #{item.id} must live in its parent's group"
          end
        end
      end

      # Caps dated items in document order. A surviving sub-item whose parent
      # fell over the cap would render orphaned, so parents count first.
      def cap_preserving_parents(dated)
        kept = dated.first(@limit)
        kept_ids = kept.map(&:id).to_set
        kept.select { |item| item.parent_id.nil? || kept_ids.include?(item.parent_id) }
      end

      def group_ids
        @group_ids ||= @groups.map(&:id).to_set
      end

      def window_bounds
        @window_bounds ||= begin
          explicit = @payload[:window] || {}
          starts = parse_date(explicit[:starts_on], "window")
          ends = parse_date(explicit[:ends_on], "window")
          derived_starts, derived_ends = derived_bounds
          [ starts || derived_starts, ends || derived_ends ]
        end
      end

      def derived_bounds
        dates = @dated_items.flat_map { |i| [ i.starts_on, i.ends_on ] } +
                @groups.select(&:dated?).flat_map { |g| [ g.starts_on, g.ends_on ] }
        dates.compact!
        return [ nil, nil ] if dates.empty?

        [ dates.min, dates.max ]
      end
    end
  end
end
