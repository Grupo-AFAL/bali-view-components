# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    # What `currency_field_group` and `percentage_field_group` share, which was
    # everything except which side the symbol goes on. They had drifted into two
    # copies of the same six lines, and both copies carried the same two bugs.
    module NumericFields
      # `step` was being set on a `type="text"` input, where it is inert: the
      # attribute only means anything on `number`, `range` and the date types.
      # It bought nothing and told the reader something false about the field,
      # so it is gone rather than moved — the input has to stay `text` for the
      # thousands delimiter to survive being typed.
      #
      # `inputmode` is what actually pays off here: a bare text input opens the
      # alphabetic keyboard on a phone, and `decimal` opens the numeric one with
      # the locale's decimal key on it. That is the only way to type an amount
      # on a touch device without switching keyboard planes.
      def numeric_field_group(method, options = {})
        opts = options.with_defaults(
          placeholder: 0,
          inputmode: "decimal",
          pattern_type: :localized_number
        )

        @template.render Bali::FieldGroupWrapper::Component.new(self, method, opts) do
          text_field(method, opts)
        end
      end

      private

      def numeric_addon(symbol)
        tag.span(symbol, class: HtmlUtils::ADDON_CLASSES)
      end
    end
  end
end
