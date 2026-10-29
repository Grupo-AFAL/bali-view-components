# frozen_string_literal: true

module Bali
  module BpmnEditor
    # BPMN diagram editor with lanes (#1489): a React Flow island, built like
    # Bali::Gantt. It knows BPMN; the host knows its business. It takes a
    # document (Bali::BpmnEditor::Data), saves the WHOLE document back to
    # `urls[:save]` and reaches the host through drawers, remote searches and
    # events — docs/api/bpmn-editor.md.
    #
    #   render Bali::BpmnEditor::Component.new(
    #     data: FlowDiagram.new(flow).to_h,
    #     editable: policy(flow).edit_diagram?,
    #     palette: :analytic,
    #     urls: { save: flow_diagram_path(flow), diagram: flow_diagram_path(flow),
    #             finalize: flow_diagram_finalization_path(flow) },
    #     id: dom_id(flow, :bpmn))
    #
    # Without `editable:` or without `urls[:save]` it is a viewer.
    class Component < ApplicationViewComponent
      URL_KEYS = %i[save diagram finalize references new_reference lane_assignees new_lane_assignee import annotations].freeze
      RULE_KEYS = %i[disabled enabled severities messages options].freeze
      # Mirrors RULE_PROFILES in model/rules/engine.js (contract_test.rb).
      RULE_PROFILES = %i[structure].freeze
      # What `rules: :structure` keeps on: what holds for any diagram with lanes
      # (broken connections, elements outside a lane, overlaps, a sub-process without
      # its reference, a duplicated connection, an element the palette does not allow).
      # Mirrors STRUCTURE_PROFILE in model/rules/engine.js (contract_test.rb).
      STRUCTURE_PROFILE = %w[R11 R18 R25 R26 B09 VIS-10].freeze
      # The option keys the rules read (`ctx.option('…')` in model/); contract_test.rb compares them.
      RULE_OPTIONS = %i[min_lanes min_activities max_activities].freeze
      # Mirrors LAYOUTS in model/layout.js (contract_test.rb).
      LAYOUTS = %i[compact straight].freeze
      # Letter, inches; mirrors LETTER in model/page.js (contract_test.rb).
      DEFAULT_PAGE = { width: 8.5, height: 11, orientation: "landscape" }.freeze
      PAGE_ORIENTATIONS = %w[landscape portrait].freeze
      FIELD_KEYS = %i[nodes lanes documentation].freeze
      # The field types a `maxlength:` (characters) or a `min:`/`max:` (a range) applies to;
      # chrome/FieldInput.jsx reads both (contract_test.rb).
      MAXLENGTH_TYPES = %w[text textarea].freeze
      RANGE_TYPES = %w[number].freeze
      REVIEW_KEYS = %i[tags compare_with compare_bar].freeze
      # The pieces of the comparison bar an app may leave out. Mirror
      # COMPARE_BAR_KEYS in chrome/CompareView.jsx (contract_test.rb).
      COMPARE_BAR_KEYS = %i[title match_note exit captions].freeze
      COMPARE_KEYS = %i[document label match].freeze
      # Mirrors COMPARE_MATCHES in model/diff.js (contract_test.rb).
      COMPARE_MATCHES = %i[auto id name].freeze
      # Mirrors COMPARE_MODES in model/compare.js (contract_test.rb).
      COMPARE_MODES = %i[side_by_side overlay].freeze
      # Mirrors CHROMES in BpmnEditor.jsx (contract_test.rb).
      CHROMES = %i[full minimal].freeze
      # What the mouse wheel does on the canvas. Mirror WHEEL_ZOOMS in BpmnEditor.jsx (contract_test.rb).
      WHEEL_ZOOMS = %w[auto true false].freeze
      # The longest label `badge_toggle:` takes. Mirror BADGE_TOGGLE_MAX in chrome/BadgeSwitch.jsx.
      BADGE_TOGGLE_MAX = 32
      # The floor of "Fit to view" (canvas/fit.js MIN_FIT_ZOOM); `min_zoom:` lowers or raises it.
      DEFAULT_MIN_ZOOM = 0.4
      MIN_ZOOM_RANGE = (0.05..1.0)
      # Mirrors FIELD_TYPES in chrome/PropertiesPanel.jsx (contract_test.rb).
      FIELD_TYPES = %w[text textarea number select multi_select readonly].freeze
      # Mirrors LEGEND_SWATCHES in chrome/Legend.jsx (contract_test.rb).
      LEGEND_SWATCHES = %w[task sub_process gateway start_event end_event external_lane external_task issue color].freeze
      DEFAULT_LEGEND = %w[task sub_process external_lane external_task issue].freeze
      EXTERNAL_LEGEND = %w[external_lane external_task].freeze
      FULL_PAGE_KEYS = %i[title close_url status].freeze
      PAGE_STATUS_KEYS = %i[label color].freeze
      # The header's hooks the island reads. Mirror PAGE_EXIT_SELECTOR,
      # PAGE_SAVE_STATUS_SELECTOR and PAGE_STATUS_SELECTOR in
      # hooks/usePageExit.js (contract_test.rb).
      PAGE_EXIT_ATTRIBUTE = "data-bpmn-page-exit"
      PAGE_SAVE_STATUS_ATTRIBUTE = "data-bpmn-page-save-status"
      PAGE_STATUS_ATTRIBUTE = "data-bpmn-page-status"

      renders_many :notices
      renders_many :actions

      attr_reader :data

      # @param data [Hash, Bali::BpmnEditor::Data] the document (contract in Bali::BpmnEditor::Data)
      # @param editable [Boolean] the island may change the document (the host authorizes).
      # @param autosave [Boolean] save with a debounce after each change (default) or only from
      #   the "Save draft" button.
      # @param lock_orientation [Boolean] keep the document's own orientation (`data[:orientation]`);
      #   the toolbar offers no switch.
      # @param external_lanes [Boolean] offer marking a lane as an external participant (default);
      #   false hides that checkbox and the external entries of the default legend.
      # @param confirm_linked_delete [Boolean] ask before deleting a sub-process linked to an
      #   entity of the app (`reference`); off by default.
      # @param open_issues [Boolean] open the pending-issues panel on load (editable only), for a
      #   page whose purpose is to show what a diagram still has to fix.
      # @param layout [Symbol] how "Tidy up" (and the first layout of a document without
      #   coordinates) arranges the flow: :compact (default) folds it into bands that fit
      #   `page:` legibly; :straight keeps the happy path in one line.
      # @param page [Hash] { width:, height: } in inches and orientation: "landscape" |
      #   "portrait" — the compact layout's target and the print/export sheet. Letter, landscape.
      # @param palette [Symbol, Array, Hash] see Bali::BpmnEditor::Palette.resolve.
      # @param legend [Hash, Array, false] { add: [{ key:, label:, swatch: }], remove: [keys] }, a
      #   full list of entries, or false to hide it.
      # @param rules [Hash, Symbol, false] { disabled: [ids], enabled: [ids], severities: { id => :warning },
      #   messages: { id => "text" }, options: { min_lanes:, min_activities:, max_activities: } };
      #   :structure keeps only STRUCTURE_PROFILE (and their blocks), for diagrams that are not
      #   process models; false runs no rule at all: no pending issues, no blocks while drawing,
      #   and «Finalize» checks nothing (the host's finalize endpoint still may).
      # @param fields [Hash] the properties panel's own fields: { nodes: { node_type (or "*") =>
      #   [{ key:, label:, type:, options:, url:, maxlength:, min:, max: }] }, lanes: [the same
      #   field schema], documentation: { maxlength: } (the built-in «Description») }.
      #   `maxlength:` (a positive integer) is for text and textarea fields, `min:`/`max:`
      #   (numbers, min <= max) for number fields; anything else raises.
      # @param urls [Hash] island endpoints, keys in URL_KEYS — see docs/api/bpmn-editor.md.
      # @param name [String] the diagram's name: title of the image and print outputs, file
      #   names, and the main participant of the .bpmn export.
      # @param watermark [String] text across the image and print outputs (e.g. "Borrador").
      # @param review [Hash] { tags: [{ key:, label:, color: }] of the review notes,
      #   compare_with: one comparison or a list of them, picked in the comparison bar — each
      #   { document: <a document like data:>, label: "Published v1.0", match: :auto (by id, then
      #   by name: the default) | :id (two versions of one document) | :name (two different
      #   documents, paired by normalized name) },
      #   compare_bar: { title:, match_note:, exit:, captions: } — false leaves that piece out
      #   (all true by default): the title when there is one comparison (a list keeps its
      #   picker), the «matched by name» note, «Close comparison» and each side's caption. }.
      # @param compare_open [Boolean, Symbol] open on load comparing against
      #   `review[:compare_with][compare_index]`: true (side by side, the default view),
      #   :side_by_side or :overlay — side by side where the overlay is not offered (two
      #   different processes). The app opens, switches and closes it later with
      #   `bali-bpmn:compare` { index, mode }; `bali-bpmn:compare-change` says what is shown.
      # @param compare_index [Integer] the comparison of `compare_with` picked on load (default 0).
      # @param selected_id [String] the node shown selected on load — read-only too. The app moves
      #   it later with the `bali-bpmn:select` event.
      # @param chrome [Symbol] :full (default) or :minimal — only the zoom controls and «Fit»: no
      #   top bar, toolbars, palette, minimap or help line, the legend folded, and the editor takes
      #   its container's height and fits again when that changes. For read-only diagrams.
      # @param min_zoom [Numeric] the floor of «Fit to view», 0.05..1 (default 0.4).
      # @param annotatable [Boolean] with `editable: false` and `urls[:annotations]`: the diagram
      #   stays read-only but review notes can be added, edited and deleted.
      # @param badges [Boolean] whether the lanes' and nodes' `appearance.badge` show on load (default true).
      #   Only the badge: the colour and the fading stay. The exports and the nodes' accessible
      #   names follow what is shown. The app changes it later with `bali-bpmn:badges` { visible }.
      # @param badge_toggle [Boolean, String] offer «Show badges», the switch that shows and hides
      #   them — in the view toolbar, or beside the zoom with `chrome: :minimal` — whenever a node of
      #   the document has a badge (default true). A String is its label instead of the default one
      #   («Show status», at most BADGE_TOGGLE_MAX characters). `false` leaves the state to the app.
      # @param wheel_zoom [Symbol, Boolean] what the mouse wheel does on the canvas. `:auto` (default):
      #   it zooms an editable diagram, one with `chrome: :minimal` (its container is sized for it),
      #   full screen and the comparison; a read-only diagram in a page scrolls the page, and
      #   Ctrl (⌘ on a Mac) + wheel zooms, with a hint that says so. `true`: always zooms. `false`:
      #   never — the zoom buttons and the pinch only, and not the pinch either.
      # @param full_page [Hash] the editor is the page: { title:, close_url:, status: } — a header
      #   with «Exit» (a link to `close_url`, a path or http(s) URL, that first waits for the
      #   pending save), the title, the status (a String, or { label:, color: } with a Bali::Tag
      #   colour; `data[:status_label]` when omitted), the save status and the `with_action`
      #   slots; the `with_notice` slots under it; the editor down to the bottom of the window.
      #   Not with `chrome: :minimal`.
      # @param bordered [Boolean] the editor's own frame — border, rounded corners and shadow, on
      #   the editor and on its loading placeholder (default true). false for an editor inside a
      #   container that draws the frame itself (a card's body); its background stays.
      # @param i18n [Hash] island strings. Defaults to Bali::BpmnEditor::Translations.island.
      #   The table travels once per render, not once per editor (#i18n_table_tag).
      # @param id [String] DOM id; also scopes the events the host sends back. Generated when
      #   omitted, so two editors on one page never share it.
      def initialize(data:, editable: false, autosave: true, lock_orientation: false, external_lanes: true,
                     open_issues: false, confirm_linked_delete: false, layout: :compact, page: DEFAULT_PAGE, palette: nil, legend: nil,
                     rules: {}, fields: {}, urls: {}, name: nil, watermark: nil, review: {}, i18n: nil, id: nil,
                     selected_id: nil, chrome: :full, min_zoom: DEFAULT_MIN_ZOOM, annotatable: false,
                     badges: true, badge_toggle: true, wheel_zoom: :auto, compare_open: false, compare_index: 0,
                     full_page: nil, bordered: true, **options)
        @data = data.is_a?(Data) ? data : Data.new(data)
        @editable = editable
        @autosave = autosave
        @lock_orientation = lock_orientation
        @external_lanes = external_lanes
        @open_issues = open_issues
        @confirm_linked_delete = resolve_boolean(:confirm_linked_delete, confirm_linked_delete)
        @layout = resolve_layout(layout)
        @page = resolve_page(page)
        @palette = Palette.resolve(palette)
        @legend = resolve_legend(legend)
        @rules = resolve_rule_setting(rules)
        @fields = resolve_fields(fields)
        @urls = resolve_urls(urls)
        @name = name
        @watermark = watermark
        @review = resolve_review(review)
        @compare_open = resolve_compare_open(compare_open)
        @compare_index = resolve_compare_index(compare_index)
        @selected_id = selected_id.presence&.to_s
        @chrome = resolve_chrome(chrome)
        @min_zoom = resolve_min_zoom(min_zoom)
        @annotatable = annotatable
        @badges = resolve_boolean(:badges, badges)
        @badge_toggle = resolve_badge_toggle(badge_toggle)
        @wheel_zoom = resolve_wheel_zoom(wheel_zoom)
        @full_page = resolve_full_page(full_page)
        @bordered = resolve_boolean(:bordered, bordered)
        @i18n = i18n
        # The locale it was built in: Lookbook builds a component inside
        # `I18n.with_locale` and renders it after that block returns.
        @locale = I18n.locale
        @id = id.presence || "bpmn-editor-#{SecureRandom.hex(4)}"
        @options = options
        if @chrome == :minimal && editable?
          raise ArgumentError, "chrome: :minimal is for read-only diagrams (it has no palette or save status); drop editable: or use chrome: :full"
        end
        return unless @chrome == :minimal && @full_page

        raise ArgumentError, "full_page: draws the whole editor around its header; it does not combine with chrome: :minimal"
      end

      def before_render
        return if full_page? || (notices.empty? && actions.empty?)

        raise ArgumentError, "with_notice and with_action are part of full_page:; pass full_page: { title:, close_url: }"
      end

      def minimal? = @chrome == :minimal

      def full_page? = !@full_page.nil?

      def bordered? = @bordered

      # The frame the island's root draws too (BpmnEditor.jsx), so the placeholder
      # it replaces is the same box.
      def border_classes = ("rounded-xl border border-base-300" if bordered?)

      def page_title = @full_page[:title]

      def page_close_url = @full_page[:close_url]

      def host_status? = !@full_page[:status].nil?

      def page_status = @full_page[:status]

      def island_i18n
        @island_i18n ||= @i18n || Translations.island(locale: @locale)
      end

      # The table's key: its content's digest, so a host's `i18n:` and each
      # locale have their own, and the same table is one key on any page.
      # Mirrors `data-bali-bpmn-i18n` in i18n.js (islandStrings).
      def i18n_key
        @i18n_key ||= Digest::SHA256.hexdigest(island_i18n_json)[0, 16]
      end

      # The strings table, written by the first editor of a render that uses
      # it; the others name it by `i18n_key`. Measured: 70 KB per editor in
      # Spanish (628 keys) — 556 KB of a 619 KB page with eight editors. A
      # Turbo Frame response gets it in every editor: Turbo keeps only the
      # frame's part of the response, and the first editor may be outside it.
      def i18n_table_tag
        return unless write_i18n_table?

        tag.script(ERB::Util.json_escape(island_i18n_json).html_safe,
                   type: "application/json", data: { bali_bpmn_i18n: i18n_key })
      end

      def wrapper_attributes
        @options.except(:class).merge(
          id: @id,
          # Minimal chrome takes its container's height (the host sizes the container).
          class: class_names("bali-bpmn-editor", { "block h-full" => minimal?, "bali-bpmn-page" => full_page? }, @options[:class]),
          data: island_values
        ).compact
      end

      private

      def island_values
        {
          controller: "bpmn-editor",
          bpmn_editor_data_value: data.to_h.to_json,
          bpmn_editor_editable_value: editable?.to_s,
          bpmn_editor_autosave_value: (!!@autosave).to_s,
          bpmn_editor_lock_orientation_value: (!!@lock_orientation).to_s,
          bpmn_editor_external_lanes_value: (!!@external_lanes).to_s,
          bpmn_editor_open_issues_value: (!!@open_issues).to_s,
          bpmn_editor_confirm_linked_delete_value: ("true" if @confirm_linked_delete),
          bpmn_editor_layout_value: @layout.to_s,
          bpmn_editor_page_value: @page.to_json,
          bpmn_editor_palette_value: @palette.to_json,
          bpmn_editor_legend_value: @legend.to_json,
          bpmn_editor_rules_value: (@rules.is_a?(Symbol) ? { profile: @rules } : @rules || {}).to_json,
          # `rules: false` travels as its own flag: a Stimulus Object value only reads objects.
          bpmn_editor_validate_value: (@rules == false ? "false" : nil),
          bpmn_editor_fields_value: @fields.to_json,
          bpmn_editor_urls_value: @urls.to_json,
          bpmn_editor_name_value: @name,
          bpmn_editor_watermark_value: @watermark,
          bpmn_editor_review_value: @review.to_json,
          bpmn_editor_i18n_key_value: i18n_key,
          bpmn_editor_selected_id_value: @selected_id,
          bpmn_editor_chrome_value: (@chrome.to_s unless @chrome == :full),
          bpmn_editor_min_zoom_value: (@min_zoom unless @min_zoom == DEFAULT_MIN_ZOOM),
          bpmn_editor_annotatable_value: (annotatable? ? "true" : nil),
          # Only when off: the island's defaults are true (index.js).
          bpmn_editor_badges_value: ("false" unless @badges),
          bpmn_editor_badge_toggle_value: ("false" unless @badge_toggle),
          bpmn_editor_badge_toggle_label_value: (@badge_toggle if @badge_toggle.is_a?(String)),
          bpmn_editor_wheel_zoom_value: (@wheel_zoom unless @wheel_zoom == "auto"),
          bpmn_editor_compare_open_value: @compare_open,
          bpmn_editor_compare_index_value: (@compare_index unless @compare_index.zero?),
          bpmn_editor_full_page_value: ("true" if full_page?),
          bpmn_editor_bordered_value: ("false" unless bordered?)
        }.compact
      end

      def island_i18n_json
        @island_i18n_json ||= island_i18n.to_json
      end

      # One view context per render: ViewComponent hands every component of
      # the render the same one through `helpers`. Never left out on what the
      # requesting page says it holds: an HTTP cache, or a back navigation
      # into a fresh tab, hands the response to a page that holds nothing.
      def write_i18n_table?
        return true if helpers.request&.headers&.[]("Turbo-Frame").present?

        written = helpers.instance_variable_get(:@bali_bpmn_i18n_written) ||
                  helpers.instance_variable_set(:@bali_bpmn_i18n_written, Set.new)
        !!written.add?(i18n_key)
      end

      # Editing without somewhere to save would lose the work on reload.
      def editable?
        !!@editable && @urls[:save].present?
      end

      # Notes on a read-only diagram, saved to their own endpoint.
      def annotatable?
        !!@annotatable && !editable? && @urls[:annotations].present?
      end

      def resolve_boolean(name, value)
        return value if value == true || value == false

        raise ArgumentError, "#{name} must be true or false, got #{value.inspect}"
      end

      def resolve_badge_toggle(value)
        return value if value == true || value == false

        label = value.is_a?(String) ? value.strip : nil
        return label if label.present? && label.length <= BADGE_TOGGLE_MAX

        raise ArgumentError, "badge_toggle must be true, false or a label of at most #{BADGE_TOGGLE_MAX} characters, " \
                             "got #{value.inspect}"
      end

      def resolve_wheel_zoom(value)
        return value.to_s if WHEEL_ZOOMS.include?(value.to_s) && [ true, false, :auto, "auto" ].include?(value)

        raise ArgumentError, "wheel_zoom must be :auto, true or false, got #{value.inspect}"
      end

      # "true" leaves the view to the island's default (model/compare.js openMode).
      def resolve_compare_open(value)
        return nil if value == false
        unless value == true || COMPARE_MODES.include?(value.to_s.to_sym)
          raise ArgumentError, "compare_open must be true, false or one of #{COMPARE_MODES.inspect}, got #{value.inspect}"
        end
        raise ArgumentError, "compare_open needs review: { compare_with: } to compare against" if @review[:compare_with].blank?

        value.to_s
      end

      def resolve_compare_index(index)
        count = Array(@review[:compare_with]).size
        return index if index.is_a?(Integer) && (index.zero? || index.between?(0, count - 1))

        raise ArgumentError, "compare_index must be an index of review compare_with (0..#{[ count - 1, 0 ].max}), got #{index.inspect}"
      end

      def resolve_full_page(page)
        return nil if page.nil?
        raise ArgumentError, "full_page must be a Hash { title:, close_url:, status: }, got #{page.inspect}" unless page.is_a?(Hash)

        page = page.symbolize_keys
        unknown = page.keys - FULL_PAGE_KEYS
        raise ArgumentError, "unknown full_page: keys #{unknown.inspect}; expected #{FULL_PAGE_KEYS.inspect}" if unknown.any?
        raise ArgumentError, "full_page needs a title:" if page[:title].blank?
        unless page[:close_url].present? && Data.navigable_url?(page[:close_url])
          raise ArgumentError, "full_page close_url: must be a path or #{Data::NAVIGABLE_SCHEMES.join('/')} URL, " \
                               "got #{page[:close_url].inspect}"
        end

        { title: page[:title].to_s, close_url: page[:close_url], status: page_status_option(page[:status]) }
      end

      def page_status_option(status)
        return nil if status.blank?
        return { label: status.to_s, color: nil } if status.is_a?(String) || status.is_a?(Symbol)
        raise ArgumentError, "full_page status: must be a String or { label:, color: }, got #{status.inspect}" unless status.is_a?(Hash)

        status = status.symbolize_keys
        unknown = status.keys - PAGE_STATUS_KEYS
        raise ArgumentError, "unknown full_page status: keys #{unknown.inspect}; expected #{PAGE_STATUS_KEYS.inspect}" if unknown.any?
        raise ArgumentError, "full_page status: needs a label:" if status[:label].blank?

        { label: status[:label].to_s, color: Bali::Color.name!("Bali::BpmnEditor full_page status", status[:color]) }
      end

      def resolve_chrome(chrome)
        return chrome.to_sym if CHROMES.include?(chrome.to_s.to_sym)

        raise ArgumentError, "chrome must be one of #{CHROMES.inspect}, got #{chrome.inspect}"
      end

      def resolve_min_zoom(min_zoom)
        return min_zoom.to_f if min_zoom.is_a?(Numeric) && MIN_ZOOM_RANGE.cover?(min_zoom.to_f)

        raise ArgumentError, "min_zoom must be a number in #{MIN_ZOOM_RANGE}, got #{min_zoom.inspect}"
      end

      def resolve_layout(layout)
        return layout.to_sym if LAYOUTS.include?(layout.to_s.to_sym)

        raise ArgumentError, "layout must be one of #{LAYOUTS.inspect}, got #{layout.inspect}"
      end

      def resolve_page(page)
        page = DEFAULT_PAGE.merge((page || {}).to_h.symbolize_keys)
        unknown = page.keys - DEFAULT_PAGE.keys
        raise ArgumentError, "unknown page: keys #{unknown.inspect}; expected #{DEFAULT_PAGE.keys.inspect}" if unknown.any?

        %i[width height].each do |side|
          next if page[side].is_a?(Numeric) && page[side].positive?

          raise ArgumentError, "page #{side}: must be a positive number of inches, got #{page[side].inspect}"
        end
        return page.merge(orientation: page[:orientation].to_s) if PAGE_ORIENTATIONS.include?(page[:orientation].to_s)

        raise ArgumentError, "page orientation: must be one of #{PAGE_ORIENTATIONS.inspect}, got #{page[:orientation].inspect}"
      end

      def resolve_urls(urls)
        urls = (urls || {}).to_h.symbolize_keys
        unknown = urls.keys - URL_KEYS
        return urls.compact if unknown.empty?

        raise ArgumentError, "unknown urls: keys #{unknown.inspect}; expected #{URL_KEYS.inspect}"
      end

      def resolve_rule_setting(rules)
        return false if rules == false
        return resolve_rules(rules) unless rules.is_a?(Symbol) || rules.is_a?(String)
        return rules.to_sym if RULE_PROFILES.include?(rules.to_sym)

        raise ArgumentError, "rules must be a Hash, false or one of #{RULE_PROFILES.inspect}, got #{rules.inspect}"
      end

      def resolve_rules(rules)
        rules = (rules || {}).to_h.deep_symbolize_keys
        unknown = rules.keys - RULE_KEYS
        raise ArgumentError, "unknown rules: keys #{unknown.inspect}; expected #{RULE_KEYS.inspect}" if unknown.any?

        (rules[:severities] || {}).each do |id, severity|
          next if Data::SEVERITIES.include?(severity.to_s)

          raise ArgumentError, "rules severities: #{id} must be one of #{Data::SEVERITIES.inspect}, got #{severity.inspect}"
        end

        {
          disabled: Array(rules[:disabled]).map(&:to_s),
          enabled: Array(rules[:enabled]).map(&:to_s),
          severities: (rules[:severities] || {}).to_h { |id, severity| [ id.to_s, severity.to_s ] },
          messages: (rules[:messages] || {}).to_h { |id, message| [ id.to_s, message.to_s ] },
          options: resolve_rule_options(rules[:options] || {})
        }
      end

      # Every option counts something (lanes, activities): a positive whole number.
      def resolve_rule_options(options)
        unknown = options.keys - RULE_OPTIONS
        raise ArgumentError, "unknown rules options #{unknown.inspect}; expected #{RULE_OPTIONS.inspect}" if unknown.any?

        options.each do |key, value|
          next if value.is_a?(Integer) && value.positive?

          raise ArgumentError, "rules options: #{key} must be a positive integer, got #{value.inspect}"
        end
      end

      def resolve_fields(fields)
        fields = (fields || {}).to_h.symbolize_keys
        unknown = fields.keys - FIELD_KEYS
        raise ArgumentError, "unknown fields: keys #{unknown.inspect}; expected #{FIELD_KEYS.inspect}" if unknown.any?

        {
          nodes: (fields[:nodes] || {}).to_h.to_h { |type, list| [ type.to_s, field_schema(list, "fields[:nodes][#{type}]") ] },
          lanes: field_schema(fields[:lanes], "fields[:lanes]"),
          documentation: documentation_field(fields[:documentation])
        }.compact
      end

      def documentation_field(options)
        return nil if options.nil?

        options = options.to_h.symbolize_keys
        unknown = options.keys - %i[maxlength]
        raise ArgumentError, "fields[:documentation]: unknown keys #{unknown.inspect}; expected [:maxlength]" if unknown.any?

        maxlength!(options[:maxlength], "fields[:documentation]")
        options
      end

      def field_schema(fields, context)
        Array(fields).map do |field|
          field = field.to_h.symbolize_keys
          raise ArgumentError, "#{context}: every field needs a key and a label" if field[:key].blank? || field[:label].blank?

          type = (field[:type] || "text").to_s
          unless FIELD_TYPES.include?(type)
            raise ArgumentError, "#{context}: #{field[:key]} has type #{type.inspect}; expected #{FIELD_TYPES.inspect}"
          end

          field_limits!(field, type, "#{context}: #{field[:key]}")
          field.merge(key: field[:key].to_s, type: type)
        end
      end

      # A nil limit is no limit, and min/max take a numeric string: before
      # these checks the island passed min/max straight to the input, so a host
      # may write `min: settings[:min]` or `min: "0"` from its config.
      def field_limits!(field, type, context)
        unless field[:maxlength].nil?
          raise ArgumentError, "#{context}: maxlength is for #{MAXLENGTH_TYPES.join('/')} fields, not #{type}" unless MAXLENGTH_TYPES.include?(type)

          maxlength!(field[:maxlength], context)
        end
        bounds = field.slice(:min, :max).compact
        return if bounds.empty?

        raise ArgumentError, "#{context}: min/max are for #{RANGE_TYPES.join('/')} fields, not #{type}" unless RANGE_TYPES.include?(type)

        bounds = bounds.to_h do |key, value|
          [ key, Float(value) ]
        rescue ArgumentError, TypeError
          raise ArgumentError, "#{context}: #{key} must be a number, got #{value.inspect}"
        end
        return unless bounds.size == 2 && bounds[:min] > bounds[:max]

        raise ArgumentError, "#{context}: min (#{field[:min]}) is greater than max (#{field[:max]})"
      end

      def maxlength!(value, context)
        return if value.is_a?(Integer) && value.positive?

        raise ArgumentError, "#{context}: maxlength must be a positive integer, got #{value.inspect}"
      end

      def resolve_review(review)
        review = (review || {}).to_h.symbolize_keys
        unknown = review.keys - REVIEW_KEYS
        raise ArgumentError, "unknown review: keys #{unknown.inspect}; expected #{REVIEW_KEYS.inspect}" if unknown.any?

        { tags: review_tags(review[:tags]), compare_with: review_comparisons(review[:compare_with]),
          compare_bar: review_compare_bar(review[:compare_bar]) }.compact
      end

      def review_compare_bar(bar)
        return nil if bar.nil?
        raise ArgumentError, "review compare_bar: must be a Hash { #{COMPARE_BAR_KEYS.join(':, ')}: }, got #{bar.inspect}" unless bar.is_a?(Hash)

        bar = bar.symbolize_keys
        unknown = bar.keys - COMPARE_BAR_KEYS
        raise ArgumentError, "unknown review compare_bar: keys #{unknown.inspect}; expected #{COMPARE_BAR_KEYS.inspect}" if unknown.any?

        bar.to_h { |key, shown| [ key, resolve_boolean("review compare_bar: #{key}", shown) ] }
      end

      def review_tags(tags)
        Array(tags).map do |tag|
          tag = tag.to_h.symbolize_keys
          raise ArgumentError, "review tags: every tag needs a key and a label" if tag[:key].blank? || tag[:label].blank?

          tag.slice(:key, :label, :color).transform_values(&:to_s)
        end
      end

      # One comparison (a Hash) or several (an Array): the island always gets the list.
      def review_comparisons(compare)
        return nil if compare.blank?

        (compare.is_a?(Array) ? compare : [ compare ]).map { |one| review_comparison(one) }
      end

      def review_comparison(compare)
        compare = compare.to_h.symbolize_keys
        unknown = compare.keys - COMPARE_KEYS
        raise ArgumentError, "unknown review compare_with: keys #{unknown.inspect}; expected #{COMPARE_KEYS.inspect}" if unknown.any?

        document = compare[:document] or raise ArgumentError, "review compare_with needs a document:"
        document = document.is_a?(Data) ? document : Data.new(document)
        match = (compare[:match] || :auto).to_s.to_sym
        unless COMPARE_MATCHES.include?(match)
          raise ArgumentError, "review compare_with match: must be one of #{COMPARE_MATCHES.inspect}, got #{compare[:match].inspect}"
        end

        { document: document.to_h, label: compare[:label].to_s, match: match.to_s }
      end

      def resolve_legend(legend)
        return [] if legend == false

        entries =
          case legend
          when nil then default_legend.map { |key| { key: key } }
          when Array then legend.map { |entry| legend_entry(entry) }
          when Hash
            legend = legend.symbolize_keys
            removed = Array(legend[:remove]).map(&:to_s)
            default_legend.reject { |key| removed.include?(key) }.map { |key| { key: key } } +
              Array(legend[:add]).map { |entry| legend_entry(entry) }
          else
            raise ArgumentError, "legend must be nil, false, an Array or a Hash, got #{legend.class}"
          end
        entries.each { |entry| check_legend_entry!(entry) }
      end

      def default_legend
        @external_lanes ? DEFAULT_LEGEND : DEFAULT_LEGEND - EXTERNAL_LEGEND
      end

      def legend_entry(entry)
        entry.is_a?(Hash) ? entry.symbolize_keys.transform_values(&:to_s) : { key: entry.to_s }
      end

      def check_legend_entry!(entry)
        swatch = entry[:swatch] || entry[:key]
        if swatch == "color" && entry[:color].blank?
          raise ArgumentError, "legend entry #{entry[:key].inspect} has swatch \"color\" but no color:"
        end
        return if LEGEND_SWATCHES.include?(swatch)

        raise ArgumentError, "legend entry #{entry[:key].inspect} needs a swatch in #{LEGEND_SWATCHES.inspect}"
      end
    end
  end
end
