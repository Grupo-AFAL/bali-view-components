# frozen_string_literal: true

module Bali
  module Utils
    class ColorPicker
      attr_reader :current

      def initialize
        @pointer = 0
        @current = colors[@pointer]
      end

      def next_color
        @pointer += 1
        reset_pointer if pointer_out_of_range?

        @current = colors[@pointer]
      end

      def opacify_current(opacity = 5)
        opacify(@current, opacity)
      end

      def opacify(color, opacity = 5)
        "#{color}#{(opacity * 255 / 10).to_s(16)}"
      end

      def gradient(color = nil, size: 10)
        (0..( size-1 )).map { |opacity| opacify(color || @current, opacity) }
      end

      private

      def pointer_out_of_range?
        @pointer >= (colors.size - 1)
      end

      def reset_pointer
        @pointer = 0
      end

      # Google charts colors samples
      def colors
        @colors ||= [
          '#22AA99', # turquoise
          '#3366CC', # blue
          '#DC3912', # red
          '#FF9900', # yellow
          '#109618', # green
          '#990099', # purple
          '#DD4477', # pink
          '#66AA00', # light_green
          '#E67300', # dark_yellow
          '#AAAA11' # olive
        ]
      end
    end
  end
end
