# frozen_string_literal: true

module Bali
  module Message
    class Preview < ApplicationViewComponentPreview
      # @param color [Symbol] select [primary, success, danger, warning, info]
      # @param size [Symbol] select [small, regular, medium, large]
      # @param style [Symbol] select [~, soft, outline, dash]
      def default(color: :primary, size: :regular, style: nil)
        render Message::Component.new(title: 'Header shortcut', size: size, color: color, style: style) do
          'Message Body'
        end
      end

      # @param color [Symbol] select [primary, success, danger, warning, info]
      # @param size [Symbol] select [small, regular, medium, large]
      # @param style [Symbol] select [~, soft, outline, dash]
      def custom_header(color: :primary, size: :regular, style: nil)
        render Message::Component.new(size: size, color: color, style: style) do |c|
          c.with_header do
            tag.h3 'Custom Header', class: 'text-error text-lg font-bold'
          end

          'Message Body'
        end
      end

      # @param color [Symbol] select [primary, success, danger, warning, info]
      # @param size [Symbol] select [small, regular, medium, large]
      # @param style [Symbol] select [~, soft, outline, dash]
      def no_header(color: :primary, size: :regular, style: nil)
        render Message::Component.new(size: size, color: color, style: style) do
          'Message Body'
        end
      end

      # @label All Combinations
      # Shows all message variants: colors, sizes, styles, and a full color x style matrix.
      def all_combinations
        render_with_template
      end
    end
  end
end
