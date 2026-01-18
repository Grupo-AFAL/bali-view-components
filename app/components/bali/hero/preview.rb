# frozen_string_literal: true

module Bali
  module Hero
    class Preview < ApplicationViewComponentPreview
      # @param size [Symbol] select [sm, md, lg]
      # @param color [Symbol] select [base, primary, secondary, accent, neutral]
      # @param centered toggle
      def default(size: :md, color: :base, centered: true)
        render Hero::Component.new(size: size, color: color, centered: centered) do |c|
          c.with_title('Hero Title')
          c.with_subtitle('Provident cupiditate voluptatem et in. Quaerat fugiat ut assumenda excepturi exercitationem quasi.')
        end
      end

      # Hero with call-to-action button
      def with_action_button
        render_with_template
      end
    end
  end
end
