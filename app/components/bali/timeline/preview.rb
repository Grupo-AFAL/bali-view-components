# frozen_string_literal: true

module Bali
  module Timeline
    class Preview < ApplicationViewComponentPreview
      # Basic Timeline
      # ----------------------
      #
      # @param position select [left, center, right]
      def default(position: :left)
        render Bali::Timeline::Component.new(position: position) do |c|
          c.with_tag_header(text: 'Start')
          c.with_tag_item(heading: 'January 2022') { c.tag.p 'Item 1' }
          c.with_tag_item(heading: 'February 2022') { c.tag.p 'Item 2' }
          c.with_tag_header(text: 'Milestone')
          c.with_tag_item(heading: 'March 2022') { c.tag.p 'Item 3' }
          c.with_tag_item(heading: 'April 2022') { c.tag.p 'Item 4' }
          c.with_tag_header(text: 'End')
        end
      end

      # Timeline with icons
      # ----------------------
      #
      # @param position select [left, center, right]
      def with_icons(position: :left)
        render Bali::Timeline::Component.new(position: position) do |c|
          c.with_tag_header(text: 'Start')
          c.with_tag_item(heading: 'January 2022', icon: 'alert') { c.tag.p 'Item 1' }
          c.with_tag_item(heading: 'February 2022', icon: 'bell') { c.tag.p 'Item 2' }
          c.with_tag_item(heading: 'March 2022', icon: 'check') { c.tag.p 'Item 3' }
          c.with_tag_item(heading: 'April 2022', icon: 'image') { c.tag.p 'Item 4' }
          c.with_tag_header(text: 'End')
        end
      end

      # Timeline with a custom header class
      # ----------------------
      #
      # @param position select [left, center, right]
      def custom_header_class(position: :left)
        render Bali::Timeline::Component.new(position: position) do |c|
          c.with_tag_header(text: 'Start', tag_class: 'badge-primary badge-outline')
          c.with_tag_item(heading: 'January 2022') { c.tag.p 'Item 1' }
          c.with_tag_item(heading: 'February 2022') { c.tag.p 'Item 2' }
          c.with_tag_item(heading: 'March 2022') { c.tag.p 'Item 3' }
          c.with_tag_item(heading: 'April 2022') { c.tag.p 'Item 4' }
          c.with_tag_header(text: 'End', tag_class: 'badge-primary badge-outline')
        end
      end
    end
  end
end
