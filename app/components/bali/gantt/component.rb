# frozen_string_literal: true

module Bali
  module Gantt
    # Gantt chart (#704 — phase 1). One component, two renderers: this phase
    # ships the shared data contract (Bali::Gantt::Data) and the server-rendered
    # `:static` mode — a generalized port of TDFlow::PortfolioGantt's board:
    # sticky two-tier header, collapsible `<details>` groups, today marker,
    # month/week/day grid, an announced cap (never a silent one) and a "no
    # dates" section for items that do not fit on the axis. `mode: :interactive`
    # (the React Flow island) arrives with phases 2-3 (#705/#719); the option is
    # signed now (D8) so host call sites never rewrite.
    #
    # All computed geometry and colors go in inline `style=` attributes — never
    # interpolated Tailwind classes, which v4 purges. Structural sizes are
    # `--gantt-*` tokens in index.css (@layer components) so hosts can retheme.
    #
    #   render Bali::Gantt::Component.new(
    #     data: serializer.as_json,     # the contract — see Bali::Gantt::Data
    #     color_by: :status,            # or :none (D9)
    #     zoom: params[:gantt_zoom],    # :auto/:day/:week/:month, via links
    #     statuses: [                   # status catalog: legend + colors
    #       { value: 'in_progress', label: t('...'), color: '--color-info' }
    #     ],
    #     group_label: 'Stage', limit: 300, id: dom_id(project, :gantt)
    #   )
    class Component < ApplicationViewComponent
      MODES = %i[static interactive].freeze
      COLOR_BYS = %i[status none].freeze
      DEFAULT_LIMIT = 300
      DEFAULT_ZOOM_PARAM = "gantt_zoom"

      attr_reader :data, :mode, :color_by, :zoom_param, :limit

      # @param data [Hash, Bali::Gantt::Data] the Gantt document (contract in Bali::Gantt::Data)
      # @param mode [Symbol] :static (server-rendered). :interactive raises until phase 3.
      # @param color_by [Symbol] :status paints bars from the status catalog; :none is all-neutral.
      # @param zoom [Symbol, String] :auto (default), :day, :week or :month — usually params[zoom_param].
      # @param zoom_param [String] query param the zoom links write (namespaced, like gantt_group_by).
      # @param zoom_links [Boolean] render the zoom switcher links.
      # @param group_label [String] header of the sticky name column.
      # @param statuses [Array<Hash>] status catalog [{ value:, label:, color: }] — color is a
      #   daisyUI variable name ("--color-info") or nil for the neutral treatment.
      # @param limit [Integer] announced cap on rendered items (nil = no cap).
      def initialize(data:, mode: :static, color_by: :status, zoom: nil,
                     zoom_param: DEFAULT_ZOOM_PARAM, zoom_links: true,
                     group_label: nil, statuses: nil, limit: DEFAULT_LIMIT,
                     id: nil, **options)
        @mode = validate_mode!(mode)
        @color_by = validate_color_by!(color_by)
        @data = data.is_a?(Data) ? data : Data.new(data, limit: limit)
        @zoom = zoom
        @zoom_param = zoom_param.to_s
        @zoom_links = zoom_links
        @group_label = group_label
        @statuses = statuses
        @limit = limit
        @id = id
        @options = options
      end

      def time_scale
        @time_scale ||= TimeScale.new(starts_on: data.window_starts_on,
                                      ends_on: data.window_ends_on,
                                      zoom: @zoom)
      end

      # Status catalog: [{ value:, label:, color: }]. Defaults to the island's
      # STATUS_VAR map with humanized labels; hosts pass their own vocabulary.
      def statuses
        @statuses ||= Colors::DEFAULT_STATUS_VARS.map do |value, var|
          { value: value, label: value.humanize, color: var }
        end
      end

      def group_label
        @group_label.presence || t(".name_column")
      end

      def renderable? = time_scale.valid? && (data.dated_items.any? || dated_groups.any?)

      def dated_groups
        @dated_groups ||= data.ordered_groups.select(&:dated?)
      end

      # Legend: only the statuses actually on screen, in catalog order —
      # offering states nobody is seeing would invent information. Statuses
      # outside the catalog close the list with the neutral treatment.
      def legend_entries
        return [] unless color_by == :status

        present = (data.dated_items.map(&:status) + dated_groups.map(&:status)).compact.uniq
        catalog = statuses.select { |entry| present.include?(entry[:value].to_s) }
        extras = (present - statuses.map { |entry| entry[:value].to_s })
                 .map { |value| { value: value, label: value.humanize, color: nil } }
        (catalog + extras).map do |entry|
          { label: entry[:label], color: color_set(entry[:value])[:solid] }
        end
      end

      # Render order: the implicit ungrouped section first, then every group in
      # document order (sub-groups indented). Groups render flat — each
      # `<details>` collapses its own rows; a parent does not swallow its
      # sub-groups, which matches how the portfolio board reads.
      def sections
        @sections ||= begin
          list = []
          list << { group: nil, depth: 0, items: data.ungrouped_items } if data.ungrouped_items.any?
          data.ordered_groups.each do |group|
            list << { group: group, depth: group.parent_id ? 1 : 0, items: data.items_for(group.id) }
          end
          list
        end
      end

      def zoom_links? = @zoom_links

      def zoom_link_options
        TimeScale::ZOOMS.map do |key|
          { zoom: key, label: t(".zoom.#{key}"), href: zoom_href(key),
            active: time_scale.resolved_zoom == key }
        end
      end

      # { solid:, fill:, border:, text: } for a status value under the current
      # color_by mode.
      def color_set(status)
        return Colors.neutral if color_by == :none || status.nil?

        Colors.status_color(status, vars: status_vars)
      end

      def bar_style(record)
        geometry = time_scale.bar_geometry(record.starts_on, record.ends_on)
        colors = color_set(record.status)
        "left: #{geometry[:left]}px; width: #{geometry[:width]}px; " \
          "background-color: #{colors[:fill]}; border-color: #{colors[:border]};"
      end

      def milestone_style(item)
        colors = color_set(item.status)
        "left: #{time_scale.x_for(item.starts_on)}px; background-color: #{colors[:solid]};"
      end

      def progress_style(item)
        colors = color_set(item.status)
        "width: #{item.percent_complete}%; background-color: #{colors[:solid]};"
      end

      def bar_title(record)
        [ record.name, "#{helpers.l(record.starts_on)} – #{helpers.l(record.ends_on)}" ].join(" · ")
      end

      def avatar_style(assignee)
        "background-color: oklch(0.6 0.14 #{Colors.hash_hue(assignee.id || assignee.name)});"
      end

      def canvas_width_css = "width: calc(var(--gantt-name-col) + #{time_scale.total_width}px)"
      def lane_width_css = "width: #{time_scale.total_width}px"

      def wrapper_attributes
        @options.except(:class).merge(
          id: @id,
          class: class_names("bali-gantt space-y-3", @options[:class]),
          data: (@options[:data] || {}).merge(
            gantt_mode: mode, gantt_color_by: color_by, gantt_zoom: time_scale.resolved_zoom
          )
        ).compact
      end

      private

      def validate_mode!(mode)
        mode = mode&.to_sym
        unless MODES.include?(mode)
          raise ArgumentError, "mode must be one of #{MODES.inspect}, got #{mode.inspect}"
        end
        if mode == :interactive
          raise ArgumentError,
                "Bali::Gantt mode: :interactive is not available yet — it ships with the React " \
                "island in phases 2-3 (#705/#719). Render mode: :static for now."
        end

        mode
      end

      def validate_color_by!(color_by)
        color_by = color_by&.to_sym
        return color_by if COLOR_BYS.include?(color_by)

        raise ArgumentError, "color_by must be one of #{COLOR_BYS.inspect}, got #{color_by.inspect}"
      end

      def status_vars
        @status_vars ||= statuses.to_h { |entry| [ entry[:value].to_s, entry[:color] ] }
      end

      # Zoom by links (read-only mode): plain GET links that rewrite only the
      # namespaced zoom param and keep every other filter on the URL.
      def zoom_href(key)
        params = helpers.request.query_parameters.merge(zoom_param => key.to_s)
        "#{helpers.request.path}?#{params.to_query}"
      end
    end
  end
end
