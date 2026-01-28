# frozen_string_literal: true

module Bali
  module Filters
    module FilterGroup
      class Component < ApplicationViewComponent
        attr_reader :group, :index, :available_attributes, :removable

        # @param group [Hash] The filter group data
        #   { combinator: 'or', conditions: [{ attribute:, operator:, value: }] }
        # @param index [Integer, String] The group index for form field naming
        # @param available_attributes [Array<Hash>] Available filterable attributes
        # @param removable [Boolean] Whether this group can be removed
        def initialize(group:, index:, available_attributes:, removable: false)
          @group = group || default_group
          @index = index
          @available_attributes = available_attributes
          @removable = removable
        end

        def combinator
          @group[:combinator] || 'or'
        end

        def conditions
          @group[:conditions] || [default_condition]
        end

        def group_field_prefix
          "q[g][#{index}]"
        end

        def and_button_classes
          class_names(
            'join-item btn btn-xs w-10',
            combinator == 'and' ? 'btn-primary' : 'btn-outline'
          )
        end

        def or_button_classes
          class_names(
            'join-item btn btn-xs w-10',
            combinator == 'or' ? 'btn-primary' : 'btn-outline'
          )
        end

        private

        def default_group
          {
            combinator: 'or',
            conditions: [default_condition]
          }
        end

        def default_condition
          {
            attribute: '',
            operator: 'cont',
            value: ''
          }
        end
      end
    end
  end
end
