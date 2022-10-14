# frozen_string_literal: true

module Bali
  module Utils
    module ColorCalculator
      def convert_to_brightness_value(background_hex_color)
        background_hex_color.scan(/../).map(&:hex).sum
      end

      def contrasting_text_color(background_hex_color)
        return if background_hex_color.blank?

        convert_to_brightness_value(background_hex_color.gsub('#', '')) > 382.5 ? '#000' : '#fff'
      end

      def tag_label(text, color, **options)
        tag.span(
          text,
          class: "tag #{options[:class] || 'is-medium'}",
          style: "background-color: #{color}; color: #{contrasting_text_color(color)}"
        )
      end
    end
  end
end
