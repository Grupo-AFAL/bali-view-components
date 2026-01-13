# frozen_string_literal: true

module Bali
  module ActionsDropdown
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :items, ->(method: :get, **options) do
        component_klass = method&.to_sym == :delete ? DeleteLink::Component : Link::Component
        component_klass.new(method: method, plain: true, **options)
      end

      # Horizontal alignment
      ALIGNMENTS = {
        start: 'dropdown-start',
        center: 'dropdown-center',
        end: 'dropdown-end'
      }.freeze

      # Vertical direction
      DIRECTIONS = {
        top: 'dropdown-top',
        bottom: 'dropdown-bottom',
        left: 'dropdown-left',
        right: 'dropdown-right'
      }.freeze

      def initialize(align: :start, direction: nil, **options)
        @align = align&.to_sym
        @direction = direction&.to_sym
        @options = prepend_class_name(options, dropdown_classes)
      end

      def render?
        items? ? items.any?(&:authorized?) : content.present?
      end

      private

      def dropdown_classes
        class_names(
          'dropdown',
          ALIGNMENTS[@align],
          DIRECTIONS[@direction]
        )
      end
    end
  end
end
