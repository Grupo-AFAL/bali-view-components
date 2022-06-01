# frozen_string_literal: true

# # frozen_string_literal: true

module Bali
  module HelpTip
    class Preview < ApplicationViewComponentPreview
      # @!group Placements

      # Default Help Tip
      # ---------------
      # Content on the top by default
      def default
        render HelpTip::Component.new do
          tag.p 'Hi, this is the help tip content'
        end
      end

      # Bottom Content
      # ---------------
      # Content on the bottom
      def bottom
        render HelpTip::Component.new(placement: 'bottom') do
          tag.p 'Hi, this is the help tip content'
        end
      end

      # Right Content
      # ---------------
      # Content on the bottom
      def right
        render HelpTip::Component.new(placement: 'right') do
          tag.p 'Hi, this is the help tip content'
        end
      end

      # Left Content
      # ---------------
      # Content on the bottom
      def left
        render HelpTip::Component.new(placement: 'left') do
          tag.p 'Hi, this is the help tip content'
        end
      end

      # @!endgroup
    end
  end
end
