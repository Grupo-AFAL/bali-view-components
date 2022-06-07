# frozen_string_literal: true

module Bali
  module Card
    class Component < ApplicationViewComponent
      renders_one :image, ->(src: nil, **options, &block) do
        if src.present?
          Image::Component.new(src: src, **options)
        else
          tag.div(**options, &block)
        end
      end

      renders_many :footer_items, FooterItem::Component

      def initialize(**options)
        @options = prepend_class_name(options, 'card-component card')
      end
    end
  end
end
