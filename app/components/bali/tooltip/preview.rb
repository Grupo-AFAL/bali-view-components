# frozen_string_literal: true

module Bali
  module Tooltip
    class Preview < ApplicationViewComponentPreview
      # @param placement select { choices: [top, bottom, left, right] }
      # @param trigger_event select { choices: [mouseenter focus, click, manual] }
      def default(placement: :top, trigger_event: 'mouseenter focus')
        render Tooltip::Component.new(placement: placement, trigger_event: trigger_event) do |c|
          c.with_trigger { tag.span 'Hover me', class: 'link link-primary' }
          tag.p 'Hi, this is the tooltip content'
        end
      end

      # Shows tooltip behavior when content is empty (no tooltip appears)
      def empty_tooltip
        render Tooltip::Component.new do |c|
          c.with_trigger { tag.span 'Link without tooltip', class: 'link' }
        end
      end

      # Common pattern: help icon with tooltip explanation
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
