# frozen_string_literal: true

module Bali
  module Tooltip
    class Preview < ApplicationViewComponentPreview
      # Default Tooltip
      # ---------------
      # Content on the top by default
      def default
        render Tooltip::Component.new do |c|
          c.trigger { tag.a 'Link with tooltip' }

          tag.p 'Hi, this is the tooltip content'
        end
      end

      def empty_tootip
        render Tooltip::Component.new do |c|
          c.trigger { tag.a 'Link without tooltip' }
        end
      end

      # @!group HelpTip

      # Default Help Tip
      # ---------------
      # Content on the top by default
      def top
        render Tooltip::Component.new(class: 'help-tip') do |c|
          c.trigger { tag.span '?' }

          tag.p 'Hi, this is the help tip content'
        end
      end

      # Bottom Content
      # ---------------
      # Content on the bottom
      def bottom
        render Tooltip::Component.new(placement: 'bottom', class: 'help-tip') do |c|
          c.trigger { tag.span '?' }

          tag.p 'Hi, this is the help tip content'
        end
      end

      # Right Content
      # ---------------
      # Content on the right
      def right
        render Tooltip::Component.new(placement: 'right', class: 'help-tip') do |c|
          c.trigger { tag.span '?' }

          tag.p 'Hi, this is the help tip content'
        end
      end

      # Left Content
      # ---------------
      # Content on the left
      def left
        render Tooltip::Component.new(placement: 'left', class: 'help-tip') do |c|
          c.trigger { tag.span '?' }

          tag.p 'Hi, this is the help tip content'
        end
      end
      # @!endgroup
    end
  end
end
