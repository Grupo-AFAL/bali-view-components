# frozen_string_literal: true

module Bali
  module Toast
    class Preview < ApplicationViewComponentPreview
      # A toast on its own is an inline alert that closes itself. Put it inside a
      # `Bali::ToastContainer` to float it over the page — positioning is the
      # container's job, not the toast's.
      #
      # @param color [Symbol] select [neutral, info, success, warning, error]
      # @param style [Symbol] select [~, soft, outline, dash]
      # @param duration number
      # @param closable toggle
      def default(color: :success, style: nil, duration: 3000, closable: true)
        render Toast::Component.new(color: color, style: style, duration: duration, closable: closable) do
          "This is a toast message!"
        end
      end

      # `duration: nil` never closes on its own, which is the toast to use for
      # something the reader has to act on.
      #
      # @param color [Symbol] select [neutral, info, success, warning, error]
      def sticky(color: :warning)
        render Toast::Component.new(color: color, duration: nil) do
          "This one stays until you close it."
        end
      end

      # @label All Colors & Styles
      def all_colors
        render_with_template
      end
    end
  end
end
