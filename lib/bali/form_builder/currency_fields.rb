# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module CurrencyFields
      DEFAULT_SYMBOL = "$"

      def currency_group(method, **options)
        numeric_group(method, **currency_options(options))
      end

      def currency_field(method, **options)
        numeric_field(method, **currency_options(options))
      end

      private

      def currency_options(options)
        symbol = options[:symbol] || DEFAULT_SYMBOL

        options.with_defaults(addon_left: numeric_addon(symbol))
      end
    end
  end
end
