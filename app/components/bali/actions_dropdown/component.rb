# frozen_string_literal: true

module Bali
  module ActionsDropdown
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :items, ->(method: :get, **options) do
        component_klass = method&.to_sym == :delete ? DeleteLink::Component : Link::Component
        component_klass.new(method: method, **prepend_class_name(options, 'dropdown-item'))
      end

      def initialize(**options)
        options.with_defaults!(
          z_index: 38,
          open_on_click: true,
          content_padding: false,
          placement: 'bottom-end'
        )

        @options = prepend_class_name(options, 'actions-dropdown-component')
        @options = prepend_data_attribute(
          options,
          'hovercard-content-class',
          'hover-card-tippy-wrapper actions-dropdown-tippy-wrapper'
        )
      end

      def render?
        items? ? items.any?(&:authorized?) : content.present?
      end
    end
  end
end
