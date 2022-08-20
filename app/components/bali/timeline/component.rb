# frozen_string_literal: true

module Bali
  module Timeline
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_many :tags, types: {
        header: Timeline::Header::Component,
        item: Timeline::Item::Component
      }

      def initialize(position: :left, **options)
        @position = position

        @options = prepend_class_name(options, 'timeline-component')
        @options = prepend_class_name(@options, 'is-centered') if position == :center
        @options = prepend_class_name(@options, 'is-rtl') if position == :right
      end
    end
  end
end
