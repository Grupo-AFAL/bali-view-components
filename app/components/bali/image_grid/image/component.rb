# frozen_string_literal: true

module Bali
  module ImageGrid
    module Image
      class FooterComponent < ApplicationViewComponent
        def initialize(**options)
          @options = options
        end

        def call
          tag.div(**footer_options) { content }
        end

        private

        attr_reader :options

        def footer_options
          options.merge(class: class_names('card-body', 'p-3', options[:class]))
        end
      end

      class Component < ApplicationViewComponent
        ASPECT_RATIOS = {
          square: 'aspect-square',
          video: 'aspect-video',
          '3/2': 'aspect-[3/2]',
          '4/3': 'aspect-[4/3]',
          '4/5': 'aspect-[4/5]',
          '16/9': 'aspect-[16/9]'
        }.freeze

        renders_one :footer, FooterComponent

        def initialize(aspect_ratio: :'3/2', **options)
          @aspect_ratio = aspect_ratio.to_sym
          @options = options
        end

        private

        attr_reader :options

        def aspect_class
          ASPECT_RATIOS[@aspect_ratio] || "aspect-#{@aspect_ratio}"
        end

        def card_classes
          class_names('card', 'bg-base-100', options[:class])
        end

        def card_attributes
          options.except(:class)
        end
      end
    end
  end
end
