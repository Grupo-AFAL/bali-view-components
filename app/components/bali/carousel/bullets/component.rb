# frozen_string_literal: true

module Bali
  module Carousel
    module Bullets
      class Component < ApplicationViewComponent
        attr_reader :hidden, :options
        attr_accessor :count

        def initialize(hidden: false, count: 0, **options)
          @hidden = hidden
          @count = count

          @options = prepend_class_name(options, 'glide__bullets')
          @options = prepend_data_attribute(@options, 'glide-el', 'controls[nav]')
        end

        def render?
          !hidden
        end
      end
    end
  end
end
