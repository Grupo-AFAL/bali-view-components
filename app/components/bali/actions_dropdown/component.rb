# frozen_string_literal: true

module Bali
  module ActionsDropdown
    class Component < ApplicationViewComponent
      attr_reader :options

      # Custom trigger slot - allows overriding the default ellipsis button
      renders_one :trigger

      # Items auto-select Link vs DeleteLink based on HTTP method.
      # Use `method: :delete` to render DeleteLink with confirmation dialog.
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

      # Menu width
      WIDTHS = {
        sm: 'w-40',
        md: 'w-52',
        lg: 'w-64',
        xl: 'w-80'
      }.freeze

      def initialize(align: :start, direction: nil, icon: 'ellipsis-h', width: :md, **options)
        @align = align&.to_sym
        @direction = direction&.to_sym
        @icon = icon
        @width = width&.to_sym
        @options = prepend_class_name(options, dropdown_classes)
      end

      def render?
        items? ? authorized_items.any? : content.present?
      end

      def authorized_items
        @authorized_items ||= items.select(&:authorized?)
      end

      private

      def dropdown_classes
        class_names(
          'dropdown',
          ALIGNMENTS[@align],
          DIRECTIONS[@direction]
        )
      end

      def trigger_classes
        'btn btn-ghost btn-sm btn-circle text-neutral-600 hover:text-neutral-800'
      end

      def menu_classes
        class_names(
          'dropdown-content menu bg-base-100 text-neutral-800 rounded-box z-1 p-2 shadow-sm',
          WIDTHS[@width]
        )
      end
    end
  end
end
