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
        @class = options.delete(:class)
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      def classes
        class_names('sortable-list-component', @class)
      end

      def data_attributes
        {
          controller: 'sortable-list',
          'sortable-list-animation-value': @animation,
          'sortable-list-disabled-value': @disabled,
          'sortable-list-group-name-value': @group_name,
          'sortable-list-handle-value': @handle,
          'sortable-list-list-id': @list_id,
          'sortable-list-list-param-name-value': @list_param_name,
          'sortable-list-position-param-name-value': @position_param_name,
          'sortable-list-resource-name-value': @resource_name,
          'sortable-list-response-kind-value': @response_kind
        }
      end
    end
  end
end
