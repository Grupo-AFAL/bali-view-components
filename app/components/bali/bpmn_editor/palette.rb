# frozen_string_literal: true

module Bali
  module BpmnEditor
    # Resolves the `palette:` option into the list of items the island shows.
    #
    # KEYS is the contract with the island's PALETTE_ITEMS (model/catalog.js);
    # test/bali/components/bpmn_editor/palette_test.rb keeps them equal.
    #
    # The presets follow the conformance sub-classes of OMG BPMN 2.0 (§2.1.1),
    # which are also the levels of Bruce Silver's "BPMN Method and Style":
    #
    # - :descriptive — what a business analyst needs to document a process: the
    #   none/user/service task, the (collapsed) sub-process, exclusive and parallel
    #   gateways, none/message/timer start, none/message/terminate end, sequence and
    #   message flow, data object and store, text annotation, group and association.
    # - :analytic — adds the other task types, the inclusive and event-based
    #   gateways and the intermediate events (timer, message, signal, conditional,
    #   link, escalation, compensation) with the matching start and end events.
    # - :full — every element the island can draw, including the complex gateway
    #   and the multiple / parallel-multiple events.
    module Palette
      KEYS = %w[
        task user_task service_task send_task receive_task script_task business_rule_task manual_task sub_process
        binary_decision exclusive_gateway parallel_gateway inclusive_gateway complex_gateway event_based_gateway
        event_based_start_gateway parallel_event_based_gateway
        lane
        sequence_flow message_flow association
        text_annotation group data_object data_collection data_input data_output data_store
        start_event timer_start_event message_start_event conditional_start_event signal_start_event
        multiple_start_event parallel_multiple_start_event
        timer_event message_event message_throw_event escalation_event compensation_event conditional_event
        link_event link_throw_event signal_event signal_throw_event multiple_event parallel_multiple_event
        end_event message_end_event error_end_event cancel_end_event compensation_end_event signal_end_event
        terminate_end_event multiple_end_event escalation_end_event
      ].freeze

      DESCRIPTIVE = %w[
        task user_task service_task sub_process
        binary_decision exclusive_gateway parallel_gateway
        lane
        sequence_flow message_flow association
        text_annotation group data_object data_store
        start_event timer_start_event message_start_event
        end_event message_end_event terminate_end_event
      ].freeze

      ANALYTIC = (DESCRIPTIVE + %w[
        send_task receive_task script_task business_rule_task manual_task
        inclusive_gateway event_based_gateway event_based_start_gateway
        data_collection data_input data_output
        conditional_start_event signal_start_event
        timer_event message_event message_throw_event escalation_event compensation_event conditional_event
        link_event link_throw_event signal_event signal_throw_event
        error_end_event compensation_end_event signal_end_event escalation_end_event
      ]).freeze

      PRESETS = { descriptive: DESCRIPTIVE, analytic: ANALYTIC, full: KEYS }.freeze
      HASH_KEYS = %i[preset items notes note_legend note_label].freeze

      module_function

      # @param option [Symbol, String, Array, Hash, nil] a preset name, the exact
      #   list of keys, or { preset:, items: { key => true | false | "disabled" },
      #   notes: { key => "text" }, note_legend: "text", note_label: "to confirm" }. note_label
      #   names the marked items in each group's header ("3 to confirm").
      # @return [Hash] { items: [{ key:, state: "enabled" | "disabled", note: }], note_legend:, note_label: }
      def resolve(option)
        config = normalize(option)
        states = preset_keys(config[:preset]).index_with { "enabled" }
        config[:items].each do |key, value|
          key = known_key!(key)
          case value.to_s
          when "true", "enabled" then states[key] = "enabled"
          when "false" then states.delete(key)
          when "disabled" then states[key] = "disabled"
          else raise ArgumentError, "palette items: #{key} must be true, false or \"disabled\", got #{value.inspect}"
          end
        end
        notes = config[:notes].to_h { |key, text| [ known_key!(key), text.to_s ] }

        {
          items: KEYS.filter_map { |key| { key: key, state: states[key], note: notes[key] }.compact if states[key] },
          note_legend: config[:note_legend]&.to_s,
          note_label: config[:note_label]&.to_s
        }.compact
      end

      def normalize(option)
        case option
        when nil then { preset: :descriptive, items: {}, notes: {} }
        when Symbol, String then { preset: option.to_sym, items: {}, notes: {} }
        when Array
          { preset: nil, items: option.to_h { |key| [ key, true ] }, notes: {} }
        when Hash
          option = option.symbolize_keys
          unknown = option.keys - HASH_KEYS
          raise ArgumentError, "unknown palette keys #{unknown.inspect}; expected #{HASH_KEYS.inspect}" if unknown.any?

          { preset: (option[:preset] || :descriptive).to_sym, items: (option[:items] || {}).to_h,
            notes: (option[:notes] || {}).to_h, note_legend: option[:note_legend], note_label: option[:note_label] }
        else
          raise ArgumentError, "palette must be a preset, an Array of keys or a Hash, got #{option.class}"
        end
      end

      def preset_keys(preset)
        return [] if preset.nil?

        PRESETS.fetch(preset) do
          raise ArgumentError, "unknown palette preset #{preset.inspect}; expected #{PRESETS.keys.inspect}"
        end
      end

      def known_key!(key)
        key = key.to_s
        return key if KEYS.include?(key)

        raise ArgumentError, "unknown palette item #{key.inspect}; see Bali::BpmnEditor::Palette::KEYS"
      end
    end
  end
end
