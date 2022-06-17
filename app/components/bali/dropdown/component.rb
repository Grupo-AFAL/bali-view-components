# frozen_string_literal: true

module Bali
  module Dropdown
    class Component < ApplicationViewComponent
      renders_one :trigger, Trigger::Component
      renders_many :items, Item::Component

      def alignment_class
        case @align
        when :right
          'is-right'
        when :center
          'is-centered'
        else
          'is-left'
        end
      end

      def initialize(hoverable: false, close_on_click: true, align: :right, **options)
        @hoverable = hoverable
        @close_on_click = close_on_click
        @options = options
        @align = align

        @options = prepend_class_name(@options, alignment_class)
        @options = prepend_class_name(@options, 'dropdown-component dropdown')
        @options = prepend_controller(@options, 'dropdown')
      end
    end
  end
end
