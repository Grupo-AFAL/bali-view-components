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
          @options = build_options(options)
        end

        def render?
          !@hidden
        end

        private

        attr_reader :previous_icon, :next_icon

        def build_options(options)
          opts = prepend_class_name(options, 'glide__arrows')
          prepend_data_attribute(opts, 'glide-el', 'controls')
        end
      end
    end
  end
end
