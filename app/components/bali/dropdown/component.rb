# frozen_string_literal: true

module Bali
  module Dropdown
    class Component < ApplicationViewComponent
      renders_one :trigger, Trigger::Component
      renders_many :items, ->(method: :get, href: nil, **options) do
        component_klass = method&.to_sym == :delete ? DeleteLink::Component : Link::Component
        component_klass.new(
          method: method, href: href, **prepend_class_name(options, 'dropdown-item')
        )
      end

      def alignment_class
        case @align
        when :right
          'is-right'
        when :up
          'is-up'
        else
          ''
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

      def render?
        items? ? items.any?(&:authorized?) : content.present?
      end
    end
  end
end
