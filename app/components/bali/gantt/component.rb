# frozen_string_literal: true

module Bali
  module Gantt
    # Gantt chart (#704/#705/#719). ONE renderer: the React Flow island.
    #
    # The component renders the island's mount point — `data-controller="gantt"`
    # and the values that ARE the island's props — with the SKELETON inside it.
    # The skeleton stopped being an option in #970 and became the mechanism: it
    # occupies the box until React's first commit retires it, and because the
    # island mounts from inside that commit, no frame shows an empty box.
    #
    # #970 removed the server-rendered `:static` board. Holding two renderers of
    # the same schedule in parity was a permanent tax on every feature, and the
    # static one had already fallen behind on eight of them (minimap, colour
    # selector, dependencies, critical path, fullscreen, design alignment,
    # filtering, column selector). The read-only portfolio case those features
    # also serve now mounts the same island with `editable:`/`manageable:` false.
    #
    # Without JavaScript there is no Gantt. The `<noscript>` inside the mount
    # says so, instead of leaving a placeholder shimmering forever.
    #
    #   render Bali::Gantt::Component.new(
    #     data: serializer.as_json,     # the contract — see Bali::Gantt::Data
    #     zoom: params[:gantt_zoom],    # :auto/:day/:week/:month
    #     statuses: [                   # status catalog the island paints with
    #       { value: 'in_progress', label: t('...'), color: '--color-info' }
    #     ],
    #     editable: policy.update?, manageable: policy.manage?,
    #     urls: { patch: schedule_path(project), schedule: schedule_path(project),
    #             dependencies: dependencies_path(project) },
    #     id: dom_id(project, :gantt)   # broadcast target
    #   )
    #
    # The island needs its bundle: `react_island_meta_tags('gantt', js:, css:)`
    # in the host layout and `startIslandLoader('gantt')` in the main bundle —
    # docs/api/gantt.md walks the whole circuit, including the mutation and
    # broadcast contracts the host implements.
    class Component < ApplicationViewComponent
      DEFAULT_ZOOM_PARAM = "gantt_zoom"

      # Options the `:static` renderer owned, removed with it in #970. They
      # would otherwise fall into `**options` and be emitted as HTML attributes
      # in silence, so each is refused by name with what replaced it — a host
      # pinned to beta.6/7 finds out at render time, not in production.
      REMOVED_OPTIONS = {
        mode: "the island is the only renderer; drop it",
        fallback: "the skeleton is the only loading state; drop it",
        limit: "the island renders the whole document; drop it",
        zoom_links: "the island's own toolbar owns the zoom; drop it",
        group_label: "the island labels its own name column; drop it",
        color_by: "the island's own toolbar owns colour-by; drop it"
      }.freeze

      # URLs the island posts to, all optional: an island with none of them is
      # a viewer. Reference implementation of every endpoint:
      # spec/dummy/app/controllers/admin/projects/.
      URL_KEYS = %i[patch dependencies schedule item_template new_group new_item].freeze

      # Rows of the skeleton. Fixed, not derived from the data: the point of the
      # skeleton is to render nothing expensive, and the island sizes itself
      # (min 360px, then the viewport) regardless of row count.
      SKELETON_ROWS = 10

      # Neutral bar placeholders: literal Tailwind pairs (offset, width) so
      # nothing is interpolated — v4 purges computed class names, and a
      # skeleton must not leak the real schedule anyway.
      SKELETON_BARS = [
        %w[ml-0 w-1/3], %w[ml-16 w-1/4], %w[ml-8 w-1/2], %w[ml-32 w-1/5],
        %w[ml-24 w-1/3], %w[ml-4 w-2/5], %w[ml-40 w-1/4], %w[ml-12 w-1/3],
        %w[ml-28 w-1/5], %w[ml-20 w-2/5]
      ].freeze

      attr_reader :data, :zoom_param

      # @param data [Hash, Bali::Gantt::Data] the Gantt document (contract in Bali::Gantt::Data)
      # @param zoom [Symbol, String] :auto (default), :day, :week or :month — usually
      #   params[zoom_param]. Resolved server-side so the island opens at the right density.
      # @param zoom_param [String] query param the island persists the zoom into (namespaced).
      # @param statuses [Array<Hash>] status catalog [{ value:, label:, color: }] — color is a
      #   daisyUI variable name ("--color-info") or nil for the neutral treatment.
      # @param catalogs [Hash] island catalogs (D11) { statuses: [...], priorities: [{ value:,
      #   label:, hue: }] }. Defaults to the `statuses` catalog.
      # @param i18n [Hash] island strings (D12). Defaults to Bali::Gantt::Translations.island.
      # @param editable [Boolean] the island may move/resize items (host authorizes).
      # @param manageable [Boolean] the island may add/remove dependencies and create records.
      # @param urls [Hash] island endpoints, keys in URL_KEYS — see docs/api/gantt.md.
      # @param date_locale [String] date-fns locale for the island ("en"/"es"); defaults to I18n.locale.
      # @param id [String] DOM id — the broadcast target (see docs/api/gantt.md).
      def initialize(data:, zoom: nil, zoom_param: DEFAULT_ZOOM_PARAM, statuses: nil,
                     catalogs: nil, i18n: nil, editable: false, manageable: false,
                     urls: {}, date_locale: nil, id: nil, **options)
        reject_removed_options!(options)
        @data = data.is_a?(Data) ? data : Data.new(data)
        @zoom = zoom
        @zoom_param = zoom_param.to_s
        @statuses = statuses
        @catalogs = catalogs
        @i18n = i18n
        @editable = editable
        @manageable = manageable
        @urls = validate_urls!(urls)
        @date_locale = date_locale
        @id = id
        @options = options
      end

      # All that survives of the server-side geometry: resolving `:auto` against
      # the window so the island does not open at its own default and rescale
      # the board under the visitor. Pixels live in JS.
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

      # Catalogs the island paints with (D11). Defaults to the status catalog,
      # so a host that only configured `statuses:` gets one vocabulary.
      def catalogs
        @catalogs ||= { statuses: statuses }
      end

      def island_i18n
        @i18n ||= Translations.island
      end

      def date_locale = (@date_locale || I18n.locale).to_s

      def skeleton_rows = SKELETON_ROWS
      def skeleton_bars = SKELETON_BARS.first(SKELETON_ROWS)

      # The component's element IS the island's mount point: the values below
      # ARE the island's props (the ReactIslandController base maps them 1:1),
      # and the skeleton the template renders inside is what React retires from
      # inside its first commit.
      #
      # `data:` is the Gantt document, so it never reaches `**options` — an
      # element that needs extra data attributes gets them from the host's own
      # wrapper, not from here.
      def wrapper_attributes
        @options.except(:class, :data).merge(
          id: @id,
          class: class_names("bali-gantt space-y-3", @options[:class]),
          data: island_values
        ).compact
      end

      private

      # `initial_zoom` is the anti-flicker detail: without it the island starts
      # at its own default (week) whatever the window says, and a board that
      # should have opened at day zoom rescales the moment it mounts. With the
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

      def reject_removed_options!(options)
        removed = options.keys.map(&:to_sym) & REMOVED_OPTIONS.keys
        return if removed.empty?

        details = removed.map { |key| "#{key}: #{REMOVED_OPTIONS.fetch(key)}" }.join("; ")
        raise ArgumentError,
              "Bali::Gantt::Component no longer accepts #{removed.inspect} — the :static " \
              "renderer was removed in #970 and the island is the only renderer (#{details}). " \
              "Migration: docs/guides/migration-v3-to-v31.md"
      end

      # A misspelled URL key would silently ship a viewer where the host meant
      # an editor — the failure would surface as "dragging does nothing".
      def validate_urls!(urls)
        urls = (urls || {}).symbolize_keys
        unknown = urls.keys - URL_KEYS
        return urls if unknown.empty?

        raise ArgumentError, "unknown urls: keys #{unknown.inspect}; expected #{URL_KEYS.inspect}"
      end
    end
  end
end
