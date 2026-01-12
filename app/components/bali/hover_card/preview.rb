# frozen_string_literal: true

module Bali
  module HoverCard
    class Preview < ApplicationViewComponentPreview
      # Default
      # --------
      #
      # @param placement select [auto, auto-start, auto-end, top, top-start, top-end, bottom, bottom-start, bottom-end, right, right-start, right-end, left, left-start, left-end]
      # @param open_on_click toggle
      # @param content_padding toggle
      def default(placement: 'auto', open_on_click: false, content_padding: true)
        render HoverCard::Component.new(
          placement: placement,
          open_on_click: open_on_click,
          content_padding: content_padding
        ) do |c|
          c.with_trigger do
            tag.p('Hover me!', class: 'text-center')
          end

          c.tag.p('Hovercard content!')
        end
      end

      # @!group Placements
      def top
        render HoverCard::Component.new(placement: 'top') do |c|
          c.with_trigger do
            tag.p('Hover me!', class: 'text-center')
          end

          c.tag.p('Hovercard content!')
        end
      end

      def right
        render HoverCard::Component.new(placement: 'right') do |c|
          c.with_trigger do
            tag.p('Hover me!', class: 'text-center')
          end

          c.tag.p('Hovercard content!')
        end
      end

      def bottom
        render HoverCard::Component.new(placement: 'bottom') do |c|
          c.with_trigger do
            tag.p('Hover me!', class: 'text-center')
          end

          c.tag.p('Hovercard content!')
        end
      end

      def left
        render HoverCard::Component.new(placement: 'left') do |c|
          c.with_trigger do
            tag.p('Hover me!', class: 'text-center')
          end

          c.tag.p('Hovercard content!')
        end
      end

      # @!endgroup

      # With Hover URL
      # --------------
      # Content is loading asyncronously from the provided url
      #
      # @param placement select [auto, auto-start, auto-end, top, top-start, top-end, bottom, bottom-start, bottom-end, right, right-start, right-end, left, left-start, left-end]
      # @param open_on_click toggle
      # @param content_padding toggle
      def with_hover_url(hover_url: '/show-content-in-hovercard', placement: 'auto',
                         open_on_click: false, content_padding: true)
        render HoverCard::Component.new(
          hover_url: hover_url,
          placement: placement,
          open_on_click: open_on_click,
          content_padding: content_padding
        ) do |c|
          c.with_trigger do
            tag.p('Hover me!', class: 'text-center')
          end
        end
      end
    end
  end
end
