# frozen_string_literal: true

module Bali
  module Timeline
    class Component < ApplicationViewComponent
      attr_reader :start_text, :end_text, :options

      renders_many :items, Timeline::Item::Component

      def initialize(position: :left, start_text: 'Start', end_text: 'End', **options)
        @position = position
        @start_text = start_text
        @end_text = end_text

        @options = prepend_class_name(options, 'timeline-component')
        @options = prepend_class_name(@options, 'is-centered') if position == :center
        @options = prepend_class_name(@options, 'is-rtl') if position == :right
      end
    end
  end
end
