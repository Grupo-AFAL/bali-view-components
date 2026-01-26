# frozen_string_literal: true

module Bali
  module Carousel
    module Arrows
      class Component < ApplicationViewComponent
        ICONS = {
          previous: 'arrow-left',
          next: 'arrow-right'
        }.freeze

        def initialize(hidden: false, previous_icon: nil, next_icon: nil, **options)
          @hidden = hidden
          @previous_icon = previous_icon || ICONS[:previous]
          @next_icon = next_icon || ICONS[:next]
          @options = options
        end

        def render?
          !@hidden
        end

        private

        attr_reader :previous_icon, :next_icon

        def component_classes
          class_names(
            'glide__arrows',
            @options[:class]
          )
        end

        def component_data
          { 'glide-el' => 'controls' }.merge(@options[:data] || {})
        end

        def html_options
          @options.except(:class, :data)
        end
      end
    end
  end
end
