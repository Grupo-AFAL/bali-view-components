# frozen_string_literal: true

module Bali
  module AdvancedFilters
    module Condition
      class Component < ApplicationViewComponent
        attr_reader :condition, :group_index, :condition_index, :available_attributes

        # @param condition [Hash] The condition data { attribute:, operator:, value: }
        # @param group_index [Integer, String] The parent group index
        # @param condition_index [Integer, String] This condition's index
        # @param available_attributes [Array<Hash>] Available filterable attributes
        def initialize(condition:, group_index:, condition_index:, available_attributes:)
          @condition = condition || {}
          @group_index = group_index
          @condition_index = condition_index
          @available_attributes = available_attributes
        end

        def attribute
          @condition[:attribute].to_s
        end

        def operator
          @condition[:operator] || 'cont'
        end

        def value
          @condition[:value]
        end

        def selected_attribute
          @available_attributes.find { |a| a[:key].to_s == attribute }
        end

        def attribute_type
          selected_attribute&.dig(:type) || :text
        end

        def attribute_options
          selected_attribute&.dig(:options) || []
        end

        # Build the Ransack-compatible field name
        # e.g., q[g][0][status_eq] for group 0, condition with attribute=status, operator=eq
        def field_name
          if attribute.present?
            "q[g][#{group_index}][#{attribute}_#{operator}]"
          else
            "q[g][#{group_index}][__ATTR___#{operator}]"
          end
        end

        def operators_for_current_type
          Operators.for_type(attribute_type)
        end

        def multiple_operator?
          %w[in not_in].include?(operator)
        end

        def range_operator?
          operator == 'between'
        end

        # Build field names for range operators (between)
        # Returns { start: "q[g][0][field_gteq]", end: "q[g][0][field_lteq]" }
        def range_field_names
          return {} if attribute.blank?

          {
            start: "q[g][#{group_index}][#{attribute}_gteq]",
            end: "q[g][#{group_index}][#{attribute}_lteq]"
          }
        end

        # Parse range values from condition
        # Range values are stored as { start: date1, end: date2 }
        def range_values
          return {} unless value.is_a?(Hash)

          { start: value[:start] || value['start'], end: value[:end] || value['end'] }
        end

        # Returns a concise, locale-aware date format for Flatpickr
        # English: "M j, Y" → "Nov 1, 2025"
        # Spanish: "j M Y" → "1 nov 2025"
        def short_date_format
          I18n.locale == :es ? 'j M Y' : 'M j, Y'
        end

        # Returns a concise, locale-aware datetime format for Flatpickr
        # English: "M j, Y H:i" → "Nov 1, 2025 14:30"
        # Spanish: "j M Y H:i" → "1 nov 2025 14:30"
        def short_datetime_format
          I18n.locale == :es ? 'j M Y H:i' : 'M j, Y H:i'
        end

        # Translations JSON for the condition Stimulus controller.
        # These are used when dynamically building inputs in JavaScript.
        def translations_json
          {
            operators: operators_translations,
            placeholders: placeholders_translations,
            boolean: boolean_translations,
            selected_count: selected_count_translation
          }.to_json
        end

        # Translations JSON for multi-select controller specifically
        def multi_select_translations_json
          {
            select_values: placeholders_translations[:select_values],
            selected_count: selected_count_translation
          }.to_json
        end

        private

        def operators_translations
          {
            text: Operators.for_type(:text),
            number: Operators.for_type(:number),
            date: Operators.for_type(:date),
            datetime: Operators.for_type(:datetime),
            select: Operators.for_type(:select),
            boolean: Operators.for_type(:boolean)
          }
        end

        def placeholders_translations
          {
            enter_value: t('bali.advanced_filters.placeholders.enter_value',
                           default: 'Enter value...'),
            number: t('bali.advanced_filters.placeholders.number', default: '0'),
            select_date: t('bali.advanced_filters.placeholders.select_date',
                           default: 'Select date...'),
            select_datetime: t('bali.advanced_filters.placeholders.select_datetime',
                               default: 'Select date & time...'),
            select_date_range: t('bali.advanced_filters.placeholders.select_date_range',
                                 default: 'Select date range...'),
            select_datetime_range: t('bali.advanced_filters.placeholders.select_datetime_range',
                                     default: 'Select date & time range...'),
            select: t('bali.advanced_filters.placeholders.select', default: 'Select...'),
            select_values: t('bali.advanced_filters.placeholders.select_values',
                             default: 'Select values...')
          }
        end

        def boolean_translations
          {
            any: t('bali.advanced_filters.boolean.any', default: 'Any'),
            yes: t('bali.advanced_filters.boolean.yes', default: 'Yes'),
            no: t('bali.advanced_filters.boolean.no', default: 'No')
          }
        end

        # rubocop:disable Style/FormatStringToken -- %{count} is Rails I18n format
        def selected_count_translation
          t('bali.advanced_filters.selected_count', default: '%{count} selected')
        end
        # rubocop:enable Style/FormatStringToken
      end
    end
  end
end
