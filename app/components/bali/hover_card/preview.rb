# frozen_string_literal: true

module Bali
  module HoverCard
    class Preview < ApplicationViewComponentPreview
      # Default
      # --------
      # A hoverable popup that displays content when triggered by mouse hover or click.
      # Uses Tippy.js for positioning and display.
      #
      # @param placement select [auto, auto-start, auto-end, top, top-start, top-end, bottom, bottom-start, bottom-end, right, right-start, right-end, left, left-start, left-end]
      # @param open_on_click toggle
      # @param content_padding toggle
      # @param arrow toggle
      def default(placement: 'auto', open_on_click: false, content_padding: true, arrow: true)
        render HoverCard::Component.new(
          placement: placement,
          open_on_click: open_on_click,
          content_padding: content_padding,
          arrow: arrow
        ) do |c|
          c.with_trigger do
            tag.button('Hover me!', class: 'btn btn-primary')
          end

          tag.p('This is the hovercard content. It can contain any HTML.')
        end
      end

      # Link Trigger
      # ------------
      # The trigger is a link of its own, and so is something inside the card.
      # With a mouse, hovering opens the card and clicking the trigger navigates;
      # on a touch screen the first tap opens the card and the second navigates.
      #
      # @param placement select [auto, auto-start, auto-end, top, top-start, top-end, bottom, bottom-start, bottom-end, right, right-start, right-end, left, left-start, left-end]
      def link_trigger(placement: 'auto')
        render_with_template(locals: { placement: placement })
      end

      # With Hover URL
      # --------------
      # Content is loaded asynchronously from the provided URL.
      # Useful for lazy-loading content or fetching data on demand.
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
            tag.button('Hover to load content', class: 'btn btn-secondary')
          end
        end
      end
    end
  end
end
