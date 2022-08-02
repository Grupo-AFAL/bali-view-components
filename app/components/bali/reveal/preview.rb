# frozen_string_literal: true

module Bali
  module Reveal
    class Preview < ApplicationViewComponentPreview
      # Reveal
      # ------
      # Displays hidden content when clicked
      #
      # @param opened toggle
      # @param show_border toggle
      def default(opened: false, show_border: false)
        render Reveal::Component.new(opened: opened) do |c|
          c.trigger(title: 'Click to see contents', show_border: show_border)

          c.tag.h1 'Revealed contents'
        end
      end
    end
  end
end
