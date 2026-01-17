# frozen_string_literal: true

module Bali
  module Carousel
    module Bullets
      class Component < ApplicationViewComponent
        def initialize(count:, hidden: false, **options)
          @count = count
          @hidden = hidden
          @options = build_options(options)
        end

        def render?
          !@hidden && @count.positive?
        end

        private

        attr_reader :count

        def build_options(options)
          opts = prepend_class_name(options, 'glide__bullets')
          prepend_data_attribute(opts, 'glide-el', 'controls[nav]')
        end
      end
    end
  end
end
