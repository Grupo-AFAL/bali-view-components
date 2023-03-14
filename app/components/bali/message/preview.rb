# frozen_string_literal: true

module Bali
  module Message
    class Preview < ApplicationViewComponentPreview
      # Basic usage
      # -------------
      # @param color select [primary, success, danger, warning, info, link]
      # @param size select [small, normal, medium, large]
      def default(color: :primary, size: :normal)
        render Message::Component.new(title: 'Header shortcut', size: size, color: color) do
          'Message Body'
        end
      end

      # Custom header
      # -------------
      # @param color select [primary, success, danger, warning, info, link]
      # @param size select [small, normal, medium, large]
      def custom_header(color: :primary, size: :normal)
        render Message::Component.new(size: size, color: color) do
          c.header do
            tag.h3 'Custom Header', class: 'has-text-danger is-size-3'
          end

          'Message Body'
        end
      end
    end
  end
end
