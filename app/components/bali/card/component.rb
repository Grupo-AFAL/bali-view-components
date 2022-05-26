# frozen_string_literal: true

module Bali
  module Card
    class Component < ApplicationViewComponent
      attr_reader :title, :description, :image, :link

      renders_one :media
      renders_many :footer_items

      def initialize(title:, description:, image: nil, link: nil, **options)
        @title = title
        @description = description
        @image = image
        @link = link
        @options = prepend_class_name(options, 'card-component card')
      end

      def image_container(&)
        return tag.div(class: 'card-image', &) if link.blank?

        link_to(link, class: 'card-image', &)
      end
    end
  end
end
