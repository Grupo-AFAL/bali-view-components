# frozen_string_literal: true

module Bali
  module HoverCard
    class Preview < ApplicationViewComponentPreview
      def with_hover_url(hover_url: '/show-content-in-hovercard')
        render HoverCard::Component.new(hover_url: hover_url) do |c|
          c.trigger do
            tag.p('Hover me!', class: 'has-text-centered')
          end
        end
      end

      def with_template
        render HoverCard::Component.new do |c|
          c.trigger do
            tag.p('Hover me!', class: 'has-text-centered')
          end

          c.template do
            tag.p('Hovercard content!')
          end
        end
      end

      # Hover Card with option open-on-click
      # --------------
      # This option will render the HoverCard component but to show you the content, you have to
      # click the link
      # @param open_on_click [Boolean]
      def open_on_click(open_on_click: true)
        render HoverCard::Component.new(open_on_click: open_on_click) do |c|
          c.trigger do
            tag.p('Click me!', class: 'has-text-centered')
          end

          c.template do
            tag.p('Hovercard content!')
          end
        end
      end
    end
  end
end
