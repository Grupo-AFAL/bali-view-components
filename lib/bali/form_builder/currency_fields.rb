# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module CurrencyFields
      DEFAULT_SYMBOL = "$"

      def currency_field_group(method, options = {})
        symbol = options[:symbol] || DEFAULT_SYMBOL

        numeric_field_group(method, options.with_defaults(addon_left: numeric_addon(symbol)))
      end
    end
  end
end
