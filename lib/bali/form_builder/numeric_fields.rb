# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    # What `currency_group` and `percentage_group` share, which was
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
      def numeric_group(method, **options)
        opts = numeric_options(options)

        @template.render Bali::FieldGroupWrapper::Component.new(self, method, opts) do
          text_field(method, opts)
        end
      end

      # The bare half the family never had. Until v3 an amount could only be
      # rendered inside a fieldset, so a currency cell in a table or a compact
      # inline filter had to hand-roll the `inputmode` and the pattern — the two
      # things that make the input usable on a phone and acceptant of a
      # localized amount — or silently go without them.
      def numeric_field(method, **options)
        text_field(method, numeric_options(options))
      end

      private

      # `delimited` is on by default here and only here: an amount is the field
      # where a missing thousands delimiter is a misreading waiting to happen,
      # and this family already renders the `text` input the delimiter needs to
      # survive being typed. `delimited: false` opts out — for a field whose
      # value is read back by something that does not expect grouping.
      def numeric_options(options)
        opts = options.with_defaults(
          placeholder: 0,
          inputmode: "decimal",
          pattern_type: :localized_number,
          delimited: true
        )

        opts[:delimited] ? delimited_number_options(opts) : opts
      end

      def numeric_addon(symbol)
        tag.span(symbol, class: HtmlUtils::ADDON_CLASSES)
      end
    end
  end
end
