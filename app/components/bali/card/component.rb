# frozen_string_literal: true

module Bali
  module Card
    class Component < ApplicationViewComponent

      attr_reader :title, :description, :image, :link
      renders_one :media
      renders_many :footer_items

      def initialize(title:, description:, image: nil, link: nil)
        @title = title
        @description = description
        @image = image
        @link = link
      end

      def set_link(link)
        @link = link
      end

      def image_container(&block)
        return tag.div class: 'card-image', &block if link.blank?

        link_to link, class: 'card-image', &block
      end
    end
  end
end