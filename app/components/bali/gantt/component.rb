# frozen_string_literal: true

module Bali
  module Gantt
    # Gantt chart (#704/#705/#719). One component, two renderers over ONE data
    # contract (Bali::Gantt::Data):
    #
    # - `mode: :static` — server-rendered board, a generalized port of
    #   TDFlow::PortfolioGantt: sticky two-tier header, collapsible `<details>`
    #   groups, today marker, month/week/day grid, an announced cap (never a
    #   silent one) and a "no dates" section for items off the axis.
    # - `mode: :interactive` (#719) — the element becomes the React Flow
    #   island's mount point (`data-controller="gantt"`, values→props) and the
    #   FALLBACK renders inside it. The island replaces those children when it
    #   mounts, so the fallback is what a visitor sees before the bundle lands
    #   and what a visitor without JavaScript keeps forever.
    #
    # `fallback:` picks what goes inside the mount: `:static` (default) paints
    # the real board — same TimeScale, same Colors, same resolved zoom as the
    # island, which is what makes the swap unremarkable; `:skeleton` paints a
    # neutral placeholder instead. afal-apps reached for the skeleton because
    # its pre-island fallback flickered, and that fallback did NOT share
    # geometry with the island (D16). Flipping the default back is a one-line
    # change: DEFAULT_FALLBACK below. Nothing about the API moves with it.
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
    #
    #   render Bali::Gantt::Component.new(          # interactive (#719)
    #     data: serializer.as_json, mode: :interactive,
    #     editable: policy.update?, manageable: policy.manage?,
    #     urls: { patch: schedule_path(project), schedule: schedule_path(project),
    #             dependencies: dependencies_path(project) },
    #     id: dom_id(project, :gantt)               # broadcast target
    #   )
    #
    # The island needs its bundle: `react_island_meta_tags('gantt', js:, css:)`
    # in the host layout and `startIslandLoader('gantt')` in the main bundle —
    # docs/api/gantt.md walks the whole circuit, including the mutation and
    # broadcast contracts the host implements.
    class Component < ApplicationViewComponent
      MODES = %i[static interactive].freeze
      FALLBACKS = %i[static skeleton].freeze
      COLOR_BYS = %i[status none].freeze
      DEFAULT_LIMIT = 300
      DEFAULT_ZOOM_PARAM = "gantt_zoom"

      # D16's single decision point. `:static` is the bet that a fallback built
      # from the island's own geometry swaps invisibly; measuring a large
      # dataset in the dummy is what settles it. Change this line and every
      # `mode: :interactive` call site that did not pass `fallback:` moves.
      DEFAULT_FALLBACK = :static

      # URLs the island posts to, all optional: an island with none of them is
      # a viewer. Reference implementation of every endpoint:
      # spec/dummy/app/controllers/admin/projects/.
      URL_KEYS = %i[patch dependencies schedule item_template new_group new_item].freeze

      # Rows of the `:skeleton` fallback. Fixed, not derived from the data: the
      # point of the skeleton is to render nothing expensive, and the island
      # sizes itself (min 360px, then the viewport) regardless of row count.
      SKELETON_ROWS = 10

      # Neutral bar placeholders: literal Tailwind pairs (offset, width) so
      # nothing is interpolated — v4 purges computed class names, and a
      # skeleton must not leak the real schedule anyway.
      SKELETON_BARS = [
        %w[ml-0 w-1/3], %w[ml-16 w-1/4], %w[ml-8 w-1/2], %w[ml-32 w-1/5],
        %w[ml-24 w-1/3], %w[ml-4 w-2/5], %w[ml-40 w-1/4], %w[ml-12 w-1/3],
        %w[ml-28 w-1/5], %w[ml-20 w-2/5]
      ].freeze

      attr_reader :data, :mode, :fallback, :color_by, :zoom_param, :limit

      # @param data [Hash, Bali::Gantt::Data] the Gantt document (contract in Bali::Gantt::Data)
      # @param mode [Symbol] :static (server-rendered) or :interactive (React island, #719).
      # @param fallback [Symbol] what renders inside the island's mount until it takes over:
      #   :static (the real board — default) or :skeleton. Ignored by mode: :static.
      # @param color_by [Symbol] :status paints bars from the status catalog; :none is all-neutral.
      # @param zoom [Symbol, String] :auto (default), :day, :week or :month — usually params[zoom_param].
      # @param zoom_param [String] query param the zoom links write (namespaced, like gantt_group_by).
      # @param zoom_links [Boolean] render the zoom switcher links.
      # @param group_label [String] header of the sticky name column.
      # @param statuses [Array<Hash>] status catalog [{ value:, label:, color: }] — color is a
      #   daisyUI variable name ("--color-info") or nil for the neutral treatment.
      # @param limit [Integer] announced cap on rendered items (nil = no cap). Caps the STATIC
      #   board only: the island receives the whole document and renders it.
      # @param catalogs [Hash] island catalogs (D11) { statuses: [...], priorities: [{ value:,
      #   label:, hue: }] }. Defaults to the `statuses` catalog the static legend already uses.
      # @param i18n [Hash] island strings (D12). Defaults to Bali::Gantt::Translations.island.
      # @param editable [Boolean] the island may move/resize items (host authorizes).
      # @param manageable [Boolean] the island may add/remove dependencies and create records.
      # @param urls [Hash] island endpoints, keys in URL_KEYS — see docs/api/gantt.md.
      # @param date_locale [String] date-fns locale for the island ("en"/"es"); defaults to I18n.locale.
      def initialize(data:, mode: :static, fallback: DEFAULT_FALLBACK, color_by: :status,
                     zoom: nil, zoom_param: DEFAULT_ZOOM_PARAM, zoom_links: true,
                     group_label: nil, statuses: nil, limit: DEFAULT_LIMIT,
                     catalogs: nil, i18n: nil, editable: false, manageable: false,
                     urls: {}, date_locale: nil, id: nil, **options)
        @mode = validate_mode!(mode)
        @fallback = validate_fallback!(fallback)
        @color_by = validate_color_by!(color_by)
        @data = data.is_a?(Data) ? data : Data.new(data, limit: limit)
        @zoom = zoom
        @zoom_param = zoom_param.to_s
        @zoom_links = zoom_links
        @group_label = group_label
        @statuses = statuses
        @limit = limit
        @catalogs = catalogs
        @i18n = i18n
        @editable = editable
        @manageable = manageable
        @urls = validate_urls!(urls)
        @date_locale = date_locale
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

      def interactive? = mode == :interactive
      def skeleton? = interactive? && fallback == :skeleton

      # Catalogs the island paints with (D11). Defaults to the same status
      # catalog the static legend uses, so a host that only configured
      # `statuses:` gets one vocabulary in both renderers.
      def catalogs
        @catalogs ||= { statuses: statuses }
      end

      def island_i18n
        @i18n ||= Translations.island
      end

      def date_locale = (@date_locale || I18n.locale).to_s

      def skeleton_rows = SKELETON_ROWS
      def skeleton_bars = SKELETON_BARS.first(SKELETON_ROWS)

      # In `:interactive` mode the component's own element is the island's
      # mount point: the values below ARE the island's props (the
      # ReactIslandController base maps them 1:1), and everything the template
      # renders inside is the fallback the island replaces on mount.
      def wrapper_attributes
        @options.except(:class).merge(
          id: @id,
          class: class_names("bali-gantt space-y-3", @options[:class]),
          data: (@options[:data] || {}).merge(
            gantt_mode: mode, gantt_color_by: color_by, gantt_zoom: time_scale.resolved_zoom
          ).merge(interactive? ? island_values : {})
        ).compact
      end

      private

      # `initial_zoom` is the anti-flicker detail: without it the island starts
      # at its own default (week) while the static fallback resolved `:auto`
      # against the window, and the swap visibly rescales every bar. With the
      # URL param present both already agree — this covers the case where it is
      # not. After mount the island owns the zoom and writes it to the URL.
      def island_values
        {
          controller: "gantt",
          gantt_data_value: data.to_h.to_json,
          gantt_catalogs_value: catalogs.to_json,
          gantt_i18n_value: island_i18n.to_json,
          gantt_editable_value: @editable.to_s,
          gantt_manageable_value: @manageable.to_s,
          gantt_zoom_param_value: zoom_param,
          gantt_initial_zoom_value: time_scale.resolved_zoom,
          gantt_date_locale_value: date_locale,
          gantt_patch_url_value: @urls[:patch],
          gantt_dependencies_url_value: @urls[:dependencies],
          gantt_schedule_url_value: @urls[:schedule],
          gantt_item_url_template_value: @urls[:item_template],
          gantt_new_group_url_value: @urls[:new_group],
          gantt_new_item_url_value: @urls[:new_item]
        }.compact
      end

      def validate_mode!(mode)
        mode = mode&.to_sym
        return mode if MODES.include?(mode)

        raise ArgumentError, "mode must be one of #{MODES.inspect}, got #{mode.inspect}"
      end

      def validate_fallback!(fallback)
        fallback = fallback&.to_sym
        return fallback if FALLBACKS.include?(fallback)

        raise ArgumentError, "fallback must be one of #{FALLBACKS.inspect}, got #{fallback.inspect}"
      end

      def validate_color_by!(color_by)
        color_by = color_by&.to_sym
        return color_by if COLOR_BYS.include?(color_by)

        raise ArgumentError, "color_by must be one of #{COLOR_BYS.inspect}, got #{color_by.inspect}"
      end

      # A misspelled URL key would silently ship a viewer where the host meant
      # an editor — the failure would surface as "dragging does nothing".
      def validate_urls!(urls)
        urls = (urls || {}).symbolize_keys
        unknown = urls.keys - URL_KEYS
        return urls if unknown.empty?

        raise ArgumentError, "unknown urls: keys #{unknown.inspect}; expected #{URL_KEYS.inspect}"
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
