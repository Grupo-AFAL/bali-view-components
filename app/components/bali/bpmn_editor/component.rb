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
      URL_KEYS = %i[save diagram finalize references new_reference lane_assignees new_lane_assignee import].freeze
      RULE_KEYS = %i[disabled enabled severities messages options].freeze
      RULE_OPTIONS = %i[min_lanes min_activities max_activities].freeze
      SEVERITIES = %w[error warning].freeze
      # Mirrors FIELD_TYPES in PropertiesPanel.jsx.
      FIELD_TYPES = %w[text textarea number select multi_select readonly].freeze
      # Mirrors the swatches Legend.jsx draws.
      LEGEND_SWATCHES = %w[task sub_process gateway start_event end_event external_lane external_task issue color].freeze
      DEFAULT_LEGEND = %w[task sub_process external_lane external_task issue].freeze

      attr_reader :data

      # @param data [Hash, Bali::BpmnEditor::Data] the document (contract in Bali::BpmnEditor::Data)
      # @param editable [Boolean] the island may change the document (the host authorizes).
      # @param read_only_notice [String] why it cannot be edited, shown above a read-only diagram.
      # @param autosave [Boolean] save with a debounce after each change (default) or only from
      #   the "Save draft" button.
      # @param auto_arrange [Boolean] after each structural edit, make room and re-route
      #   (default); the user can switch it off from the canvas toolbar.
      # @param palette [Symbol, Array, Hash] see Bali::BpmnEditor::Palette.resolve.
      # @param legend [Hash, Array, false] { add: [{ key:, label:, swatch: }], remove: [keys] }, a
      #   full list of entries, or false to hide it.
      # @param rules [Hash] { disabled: [ids], enabled: [ids], severities: { id => :warning },
      #   messages: { id => "text" }, options: { min_lanes:, min_activities:, max_activities: } }.
      # @param node_fields [Hash] { node_type (or "*") => [{ key:, label:, type:, options:, url: }] }.
      # @param lane_fields [Array] the same field schema, for lanes.
      # @param urls [Hash] island endpoints, keys in URL_KEYS — see docs/api/bpmn-editor.md.
      # @param name [String] the diagram's name: title of the image and print outputs, file
      #   names, and the main participant of the .bpmn export.
      # @param watermark [String] text across the image and print outputs (e.g. "Borrador").
      # @param annotation_tags [Array] tags of the review notes: [{ key:, label:, color: }].
      # @param compare_with [Hash] another version to compare against:
      #   { document: <a document like data:>, label: "Published v1.0" }.
      # @param i18n [Hash] island strings. Defaults to Bali::BpmnEditor::Translations.island.
      # @param id [String] DOM id; also scopes the events the host sends back.
      def initialize(data:, editable: false, read_only_notice: nil, autosave: true, auto_arrange: true, palette: nil,
                     legend: nil, rules: {}, node_fields: {}, lane_fields: [], urls: {}, name: nil,
                     watermark: nil, annotation_tags: [], compare_with: nil, i18n: nil, id: nil, **options)
        @data = data.is_a?(Data) ? data : Data.new(data)
        @editable = editable
        @read_only_notice = read_only_notice
        @autosave = autosave
        @auto_arrange = auto_arrange
        @palette = Palette.resolve(palette)
        @legend = resolve_legend(legend)
        @rules = validate_rules!(rules)
        @node_fields = validate_node_fields!(node_fields)
        @lane_fields = validate_fields!(lane_fields, "lane_fields")
        @urls = validate_urls!(urls)
        @name = name
        @watermark = watermark
        @annotation_tags = validate_annotation_tags!(annotation_tags)
        @compare_with = resolve_compare(compare_with)
        @i18n = i18n
        @id = id
        @options = options
      end

      def island_i18n
        @island_i18n ||= @i18n || Translations.island
      end

      def wrapper_attributes
        @options.except(:class, :data).merge(
          id: @id,
          class: class_names("bali-bpmn-editor", @options[:class]),
          data: island_values
        ).compact
      end

      private

      def island_values
        {
          controller: "bpmn-editor",
          bpmn_editor_data_value: data.to_h.to_json,
          bpmn_editor_editable_value: editable?.to_s,
          bpmn_editor_read_only_notice_value: @read_only_notice,
          bpmn_editor_autosave_value: (!!@autosave).to_s,
          bpmn_editor_auto_arrange_value: (!!@auto_arrange).to_s,
          bpmn_editor_palette_value: @palette.to_json,
          bpmn_editor_legend_value: @legend.to_json,
          bpmn_editor_rules_value: @rules.to_json,
          bpmn_editor_node_fields_value: @node_fields.to_json,
          bpmn_editor_lane_fields_value: @lane_fields.to_json,
          bpmn_editor_urls_value: @urls.to_json,
          bpmn_editor_name_value: @name,
          bpmn_editor_watermark_value: @watermark,
          bpmn_editor_annotation_tags_value: @annotation_tags.to_json,
          bpmn_editor_compare_value: @compare_with&.to_json,
          bpmn_editor_i18n_value: island_i18n.to_json
        }.compact
      end

      # Editing without somewhere to save would lose the work on reload.
      def editable?
        !!@editable && @urls[:save].present?
      end

      def validate_urls!(urls)
        urls = (urls || {}).to_h.symbolize_keys
        unknown = urls.keys - URL_KEYS
        return urls.compact if unknown.empty?

        raise ArgumentError, "unknown urls: keys #{unknown.inspect}; expected #{URL_KEYS.inspect}"
      end

      def validate_rules!(rules)
        rules = (rules || {}).to_h.deep_symbolize_keys
        unknown = rules.keys - RULE_KEYS
        raise ArgumentError, "unknown rules: keys #{unknown.inspect}; expected #{RULE_KEYS.inspect}" if unknown.any?

        (rules[:severities] || {}).each do |id, severity|
          next if SEVERITIES.include?(severity.to_s)

          raise ArgumentError, "rules severities: #{id} must be one of #{SEVERITIES.inspect}, got #{severity.inspect}"
        end
        unknown_options = (rules[:options] || {}).keys - RULE_OPTIONS
        if unknown_options.any?
          raise ArgumentError, "unknown rules options #{unknown_options.inspect}; expected #{RULE_OPTIONS.inspect}"
        end

        {
          disabled: Array(rules[:disabled]).map(&:to_s),
          enabled: Array(rules[:enabled]).map(&:to_s),
          severities: (rules[:severities] || {}).to_h { |id, severity| [ id.to_s, severity.to_s ] },
          messages: (rules[:messages] || {}).to_h { |id, message| [ id.to_s, message.to_s ] },
          options: rules[:options] || {}
        }
      end

      def validate_node_fields!(node_fields)
        (node_fields || {}).to_h.to_h do |type, fields|
          [ type.to_s, validate_fields!(fields, "node_fields[#{type}]") ]
        end
      end

      def validate_fields!(fields, context)
        Array(fields).map do |field|
          field = field.to_h.symbolize_keys
          raise ArgumentError, "#{context}: every field needs a key and a label" if field[:key].blank? || field[:label].blank?

          type = (field[:type] || "text").to_s
          unless FIELD_TYPES.include?(type)
            raise ArgumentError, "#{context}: #{field[:key]} has type #{type.inspect}; expected #{FIELD_TYPES.inspect}"
          end

          field.merge(key: field[:key].to_s, type: type)
        end
      end

      def validate_annotation_tags!(tags)
        Array(tags).map do |tag|
          tag = tag.to_h.symbolize_keys
          raise ArgumentError, "annotation_tags: every tag needs a key and a label" if tag[:key].blank? || tag[:label].blank?

          tag.slice(:key, :label, :color).transform_values(&:to_s)
        end
      end

      def resolve_compare(compare)
        return nil if compare.blank?

        compare = compare.to_h.symbolize_keys
        document = compare[:document] or raise ArgumentError, "compare_with needs a document:"
        document = document.is_a?(Data) ? document : Data.new(document)
        { document: document.to_h, label: compare[:label].to_s }
      end

      def resolve_legend(legend)
        return [] if legend == false

        entries =
          case legend
          when nil then DEFAULT_LEGEND.map { |key| { key: key } }
          when Array then legend.map { |entry| legend_entry(entry) }
          when Hash
            legend = legend.symbolize_keys
            removed = Array(legend[:remove]).map(&:to_s)
            DEFAULT_LEGEND.reject { |key| removed.include?(key) }.map { |key| { key: key } } +
              Array(legend[:add]).map { |entry| legend_entry(entry) }
          else
            raise ArgumentError, "legend must be nil, false, an Array or a Hash, got #{legend.class}"
          end
        entries.each { |entry| validate_legend_entry!(entry) }
      end

      def legend_entry(entry)
        entry.is_a?(Hash) ? entry.symbolize_keys.transform_values(&:to_s) : { key: entry.to_s }
      end

      def validate_legend_entry!(entry)
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
