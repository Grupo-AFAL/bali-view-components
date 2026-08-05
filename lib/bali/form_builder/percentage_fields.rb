# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module PercentageFields
      DEFAULT_SYMBOL = "%"

      def percentage_group(method, **options)
        numeric_group(method, **percentage_options(options))
      end

      def percentage_field(method, **options)
        numeric_field(method, **percentage_options(options))
      end

      private

      def percentage_options(options)
        symbol = options[:symbol] || DEFAULT_SYMBOL

        options.with_defaults(addon_right: numeric_addon(symbol))
      end
    end
  end
end
