# frozen_string_literal: true

module Bali
  module SortableList
    class Component < ApplicationViewComponent
      renders_many :items, Item::Component

      BASE_CLASSES = 'sortable-list-component p-0 [&_.handle]:cursor-grab'

      DEFAULTS = {
        position_param_name: 'position',
        list_param_name: 'list_id',
        response_kind: :html,
        disabled: false,
        animation: 150
      }.freeze

      # @param resource_name [String] name of the resource being updated. e.g. 'task'
      # @param position_param_name [String] name of the position parameter sent to the server
      # @param list_param_name [String] name of the list parameter sent to the server
      # @param group_name [String] name to group multiple lists to be able to drag items across them
      # @param list_id [String, Integer] Identifier for each list to move items between them
      # @param response_kind [Symbol] :turbo_stream or :html
      # @param handle [String] CSS selector for the drag handle
      # @param disabled [Boolean] disable dragging of items
      # @param animation [Integer] duration of the animation in milliseconds
      #
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        resource_name: nil,
        position_param_name: DEFAULTS[:position_param_name],
        list_param_name: DEFAULTS[:list_param_name],
        group_name: nil,
        list_id: nil,
        response_kind: DEFAULTS[:response_kind],
        handle: nil,
        disabled: DEFAULTS[:disabled],
        animation: DEFAULTS[:animation],
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
        @options = build_options(options)
      end
      # rubocop:enable Metrics/ParameterLists

      private

      attr_reader :options

      def build_options(opts)
        result = prepend_class_name(opts, BASE_CLASSES)
        result = prepend_controller(result, 'sortable-list')
        prepend_values(result, 'sortable-list', controller_values)
      end

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
