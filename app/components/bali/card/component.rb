# frozen_string_literal: true

module Bali
  module Card
    class Component < ApplicationViewComponent
      renders_one :image, ->(src: nil, **options, &block) do
        # if block_given?
        #   tag.div(**options, &block)
        # else
        if src.present?
          Image::Component.new(src: src, **options)
        else
          tag.div(**options, &block)
        end
        # end
      end
      # renders_one :alt_image, Image::Component
      renders_many :footer_items, FooterItem::Component

      def initialize(**options)
        @options = prepend_class_name(options, 'card-component card')
      end
    end
  end
end
