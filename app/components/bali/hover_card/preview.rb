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
    end
  end
end
