# frozen_string_literal: true

module Bali
  module Carousel
    module Arrows
      class Component < ApplicationViewComponent
        attr_reader :hidden, :options, :previous_icon, :next_icon

        def initialize(hidden: false, **options)
          @hidden = hidden
          @previous_icon = options.delete(:previous_icon) || 'arrow-left'
          @next_icon = options.delete(:next_icon) || 'arrow-right'

          @options = prepend_class_name(options, 'glide__arrows')
          @options = prepend_data_attribute(@options, 'glide-el', 'controls')

        end

        def render?
          !hidden
        end
      end
    end
  end
end
