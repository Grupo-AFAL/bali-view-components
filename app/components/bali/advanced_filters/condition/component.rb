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
      end
    end
  end
end
