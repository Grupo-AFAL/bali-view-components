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
          Bali::AdvancedFilters::Component.new(
            url: '',
            available_attributes: []
          ).operators_for_type(attribute_type)
        end

        def multiple_operator?
          %w[in not_in].include?(operator)
        end
      end
    end
  end
end
