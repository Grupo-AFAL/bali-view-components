# frozen_string_literal: true

module Bali
  module SortableList
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :items, Item::Component

      # @param resource_name [String] name of the resource being updated. e.g. 'task'
      # @param position_param_name [String] name of the position parameter sent to the server
      # @param list_param_name [String] name of the list parameter sent to the server
      # @param group_name [String] name to group multiple lists to be able to drag items across them
      # @param list_id [String|Integer] Identifier for each list to move items between them
      # @param response_kind [Symbol] :turbo_stream or :html
      # @param handle [String] class_name for the handle
      # @param disabled [Boolean] disabled moving of items
      # @param animation [Integer] duration of the animation in miliseconds
      #
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        resource_name: nil,
        position_param_name: 'position',
        list_param_name: 'list_id',
        group_name: nil,
        list_id: nil,
        response_kind: :html,
        handle: nil,
        disabled: false,
        animation: 150,
        **options
      )
        @resource_name = resource_name
        @position_param_name = position_param_name
        @list_param_name = list_param_name
        @group_name = group_name
        @list_id = list_id
        @response_kind = response_kind
        @handle = handle
        @disabled = disabled
        @animation = animation

        @options = prepend_class_name(options, 'sortable-list-component p-0 [&_.handle]:cursor-grab')
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
