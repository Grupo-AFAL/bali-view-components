# frozen_string_literal: true

module Bali
  module ActionsDropdown
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :items, ->(method: :get, **options) do
        component_klass = method&.to_sym == :delete ? DeleteLink::Component : Link::Component
        component_klass.new(method: method, plain: true, **options)
      end

      def initialize(position: :start, **options)
        @position = position
        @options = prepend_class_name(options, dropdown_classes)
      end

      def render?
        items? ? items.any?(&:authorized?) : content.present?
      end

      private

      def dropdown_classes
        class_names(
          'dropdown',
          'dropdown-end': @position == :end,
          'dropdown-start': @position == :start
        )
      end
    end
  end
end
