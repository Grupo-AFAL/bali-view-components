# frozen_string_literal: true

module Bali
  module ActionsDropdown
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :items, ->(method: :get, **options) do
        component_klass = method&.to_sym == :delete ? DeleteLink::Component : Link::Component
        component_klass.new(method: method, **prepend_class_name(options, 'menu-item'))
      end

      def initialize(**options)
        options.with_defaults!(
          z_index: 38,
          open_on_click: true,
          content_padding: false,
          placement: 'bottom-end'
        )

        @options = prepend_class_name(options, 'actions-dropdown')
        @options = prepend_data_attribute(
          options,
          'hovercard-content-class',
          'menu bg-base-100 rounded-box shadow-lg min-w-40'
        )
      end

      def render?
        items? ? items.any?(&:authorized?) : content.present?
      end
    end
  end
end
