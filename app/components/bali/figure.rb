# frozen_string_literal: true

module Bali
  # How Bali writes a number it prints as a figure: a thousands comma and a decimal point,
  # whatever the host's locale. rails-i18n's `es` writes 13.887 unless the host overrides
  # `number.format`, and the fleet is Mexican.
  module Figure
    # `separator:` too: with the delimiter alone, a Float under rails-i18n's `es` comes out 13,887,5.
    def self.delimited(value) = ActiveSupport::NumberHelper.number_to_delimited(value, delimiter: ",", separator: ".")
  end
end
