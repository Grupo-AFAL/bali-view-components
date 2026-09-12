# frozen_string_literal: true

require "zlib"

module Bali
  module Utils
    module ColorCalculator
      # Colours from Bali::Status::Component::PALETTE that deterministic_color
      # never picks: `slate` and `gray` read as "disabled"/"empty" states, and
      # no user should look switched-off just because of how their name hashes.
      DETERMINISTIC_EXCLUDED = %i[slate gray].freeze

      def convert_to_brightness_value(background_hex_color)
        background_hex_color.scan(/../).map(&:hex).sum
      end

      def contrasting_text_color(background_hex_color)
        return if background_hex_color.blank?

        convert_to_brightness_value(background_hex_color.gsub("#", "")) > 382.5 ? "#000" : "#fff"
      end

      # Hashes a string to a stable { bg:, fg: } pair from the fixed Status
      # palette (contrast already resolved, theme-independent): the same seed
      # maps to the same colour on every render, process and DaisyUI theme.
      # Collisions (two seeds, one colour) are expected and fine.
      #
      # Zlib.crc32 and not String#hash on purpose — the latter is randomized
      # per process, which would reshuffle every avatar on each deploy.
      def deterministic_color(seed)
        palette = Bali::Status::Component::PALETTE.except(*DETERMINISTIC_EXCLUDED)
        keys = palette.keys
        palette.fetch(keys[Zlib.crc32(seed.to_s) % keys.size])
      end
    end
  end
end
