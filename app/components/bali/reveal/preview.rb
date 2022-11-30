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
          c.trigger(show_border: show_border) do |trigger|
            trigger.title do
              tag.div('Click to see contents')
            end
          end

          c.tag.h1 'Revealed contents'
        end
      end

      # @param opened toggle
      # @param show_border toggle
      def with_icon_and_title(opened: false, show_border: false)
        render_with_template(
          template: 'bali/reveal/previews/with_icon_and_title',
          locals: { opened: opened, show_border: show_border }
        )
      end
    end
  end
end
