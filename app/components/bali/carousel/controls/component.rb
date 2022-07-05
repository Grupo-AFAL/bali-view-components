# frozen_string_literal: true

module Bali
  module Carousel
    module Controls
      class Component < ApplicationViewComponent
        attr_reader :hidden, :options, :bullets, :previous_icon, :next_icon
        attr_accessor :bullets_count

        def initialize(hidden: false, bullets: {}, **options)
          @hidden = hidden
          @options = options
          @previous_icon = options.delete(:previous_icon)
          @next_icon = options.delete(:next_icon)
          @bullets_count = bullets.delete(:count) || 0

          @options = prepend_class_name(options, 'glide__arrows')
          @options = prepend_data_attribute(@options, 'glide-el', 'controls')

          @bullets = prepend_class_name(bullets, 'glide__bullets')
          @bullets = prepend_data_attribute(@bullets, 'glide-el', 'controls[nav]')
        end
      end
    end
  end
end
