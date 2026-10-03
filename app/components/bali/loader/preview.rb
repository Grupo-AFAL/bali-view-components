# frozen_string_literal: true

module Bali
  module Loader
    class Preview < ApplicationViewComponentPreview
      # @param text text
      # @param type [Symbol] select [spinner, dots, ring, ball, bars, infinity]
      # @param size [Symbol] select [xs, sm, md, lg, xl]
      # @param color [Symbol] select [~, primary, secondary, accent, neutral, info, success, warning, error]
      def default(text: 'Loading...', type: :spinner, size: :lg, color: nil)
        render Bali::Loader::Component.new(text: text, type: type, size: size, color: color)
      end

      def without_text
        render Bali::Loader::Component.new(hide_text: true)
      end

      def all_types
        render_with_template(locals: { types: Bali::Loader::Component::TYPES.keys })
      end

      # Every `color:`. The spinner takes the colour itself; the text under it takes
      # `text-soft-<color>`, which reads on the page where the colour does not.
      def all_colors
        render_with_template(locals: { colors: Bali::Loader::Component::COLORS.keys })
      end
    end
  end
end
