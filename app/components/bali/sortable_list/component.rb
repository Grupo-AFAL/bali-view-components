# frozen_string_literal: true

module Bali
  module SortableList
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :items, Item::Component

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        animation: nil,
        disabled: false,
        group_name: nil,
        handle: nil,
        list_id: nil,
        list_param_name: nil,
        resource_name: nil,
        response_kind: nil,
        position_param_name: nil,
        **options
      )
        @animation = animation
        @disabled = disabled
        @group_name = group_name
        @handle = handle
        @list_id = list_id
        @list_param_name = list_param_name
        @resource_name = resource_name
        @response_kind = response_kind
        @position_param_name = position_param_name

        @options = prepend_class_name(options, 'sortable-list-component')
        @options = prepend_controller(@options, 'sortable-list')
        @options = prepend_values(@options, 'sortable-list', controller_values)
      end
      # rubocop:enable Metrics/ParameterLists

      def controller_values
        {
          animation: @animation,
          disabled: @disabled,
          group_name: @group_name,
          handle: @handle,
          list_id: @list_id,
          list_param_name: @list_param_name,
          position_param_name: @position_param_name,
          resource_name: @resource_name,
          response_kind: @response_kind
        }
      end
    end
  end
end
