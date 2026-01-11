# frozen_string_literal: true

module Bali
  module Tooltip
    class Preview < ApplicationViewComponentPreview
      # @param placement [Symbol] select [top, bottom, left, right]
      def default(placement: :top)
        render Tooltip::Component.new(placement: placement) do |c|
          c.with_trigger { tag.span 'Hover me', class: 'link link-primary' }

          tag.p 'Hi, this is the tooltip content'
        end
      end

      def empty_tooltip
        render Tooltip::Component.new do |c|
          c.with_trigger { tag.span 'Link without tooltip', class: 'link' }
        end
      end

      def help_tip
        render Tooltip::Component.new(class: 'help-tip') do |c|
          c.with_trigger do
            tag.span '?',
                     class: 'w-6 h-6 rounded-full border border-neutral flex items-center justify-center text-sm'
          end

          tag.p 'Hi, this is the help tip content'
        end
      end

      def all_placements
        render_with_template
      end
    end
  end
end
