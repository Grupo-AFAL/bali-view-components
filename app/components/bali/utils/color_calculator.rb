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
    end
  end
end
