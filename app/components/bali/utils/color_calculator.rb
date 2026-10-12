# frozen_string_literal: true

require "zlib"

module Bali
  module Utils
    module ColorCalculator
      # Colours from Bali::Status::Component::PALETTE that deterministic_color
      # never picks: `slate` and `gray` read as "disabled"/"empty" states, and
      # no user should look switched-off just because of how their name hashes.
      DETERMINISTIC_EXCLUDED = %i[slate gray].freeze

      # Black or white, whichever has the higher WCAG contrast ratio over the hex.
      # Not R+G+B: blue weighs 7% of the luminance and a third of the sum, which put
      # black on #535BEB at 4.06:1 where white gives 5.17 (#1373). The alpha of
      # #rgba / #rrggbbaa is ignored, the backdrop it blends with is unknown here.
      def contrasting_text_color(background_hex_color)
        return if background_hex_color.blank?

        luminance = relative_luminance(background_hex_color)
        on_black = (luminance + 0.05) / 0.05
        on_white = 1.05 / (luminance + 0.05)
        on_black > on_white ? "#000" : "#fff"
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

      private

      def relative_luminance(hex)
        digits = hex.delete("#")
        digits = digits.chars.map { |digit| digit * 2 }.join if digits.size <= 4
        red, green, blue = digits.scan(/../).map { |pair| linear_channel(pair.hex / 255.0) }
        (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
      end

      def linear_channel(value)
        value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
      end
    end
  end
end
