# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module NumberFields
      # Attributes the browser only enforces on a native `number` input, dropped
      # by `delimited: true` along with the input type they belong to. Leaving
      # them on the `text` input would render `min="0" max="1000000"` — inert,
      # and reading at the call site like a bound the browser is checking. The
      # same measurement retired `step` from `numeric_group`.
      NATIVE_ONLY_ATTRIBUTES = %i[min max step].freeze

      def number_group(method, **options)
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          number_field(method, options)
        end
      end

      # `delimited: true` groups the thousands as the amount is typed, for the
      # figures long enough to be misread on sight — a budget, a mileage, a peso
      # amount. It is opt-in rather than the default because it costs the field
      # its native type, and it cannot keep that type: a `number` input refuses
      # to store a value with a delimiter in it, reporting the empty string and
      # no caret. So the field becomes `text` and picks up the `inputmode` and
      # the locale-aware `pattern` that make a grouped amount typable on a phone
      # and checkable by the browser — the same three `currency_group` has
      # rendered since v3, which is why the grouping is on by default there and
      # opt-in here.
      #
      # `Bali::Concerns::NumericAttributesWithCommas` is the other half: without
      # `currency_attribute`/`percentage_attribute` on the model, a grouped
      # amount reaches a numeric column as a String and Rails casts `"1,500,200"`
      # to 1.
      def number_field(method, options = {})
        return delimited_number_field(method, options) if options[:delimited]

        field_helper(method, super(method, field_options(method, options)), options)
      end

      private

      def delimited_number_field(method, options)
        text_field(
          method,
          delimited_number_options(options.except(*NATIVE_ONLY_ATTRIBUTES))
            .with_defaults(inputmode: "decimal", pattern_type: :localized_number)
        )
      end
    end
  end
end
