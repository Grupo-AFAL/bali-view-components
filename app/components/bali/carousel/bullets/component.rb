# frozen_string_literal: true

module Bali
  module Carousel
    module Bullets
      class Component < ApplicationViewComponent
        def initialize(count:, hidden: false, **options)
          @count = count
          @hidden = hidden
          @options = options
        end

        def render?
          !@hidden && @count.positive?
        end

        private

        attr_reader :count

        def component_classes
          class_names(
            'glide__bullets',
            @options[:class]
          )
        end

        def component_data
          { 'glide-el' => 'controls[nav]' }.merge(@options[:data] || {})
        end

        def html_options
          @options.except(:class, :data)
        end
      end
    end
  end
end
