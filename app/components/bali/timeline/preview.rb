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
          c.item(heading: 'January 2022') { c.tag.p 'Item 1' }
          c.item(heading: 'February 2022') { c.tag.p 'Item 2' }
          c.item(heading: 'March 2022') { c.tag.p 'Item 3' }
          c.item(heading: 'April 2022') { c.tag.p 'Item 4' }
        end
      end

      # Timeline with icons
      # ----------------------
      #
      # @param position select [left, center, right]
      def with_icons(position: :left)
        render Bali::Timeline::Component.new(position: position) do |c|
          c.item(heading: 'January 2022', icon: 'alert') { c.tag.p 'Item 1' }
          c.item(heading: 'February 2022', icon: 'bell') { c.tag.p 'Item 2' }
          c.item(heading: 'March 2022', icon: 'check') { c.tag.p 'Item 3' }
          c.item(heading: 'April 2022', icon: 'image') { c.tag.p 'Item 4' }
        end
      end
    end
  end
end
