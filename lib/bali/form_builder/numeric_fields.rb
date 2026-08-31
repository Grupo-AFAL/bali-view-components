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
        opts = numeric_options(method, options)

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
        text_field(method, numeric_options(method, options))
      end

      private

      # `delimited` is opt-in here too, and that is a deliberate reversal. An
      # amount is exactly the field where a missing thousands delimiter is a
      # misreading waiting to happen, so turning it on by default was tempting
      # and looked free — this family already renders the `text` input the
      # delimiter needs to survive being typed.
      #
      # It is not free. The delimiter changes what the field SUBMITS, and a
      # grouped amount only survives the trip if the model carries
      # `currency_attribute`/`percentage_attribute` from
      # `Bali::Concerns::NumericAttributesWithCommas`. Without it Rails casts
      # `"1,500,200"` to 1 — no exception, no validation error, a 1 in a money
      # column. Measured across the group's apps before this defaulted to false:
      # twelve live call sites over `investment`, `expenses`, `unit_price`,
      # `lunch_price`, `declared_value`, `cost` and three percentages, and not one
      # model including the concern. Every one of them would have started storing
      # 1 on the upgrade, silently.
      #
      # Today those fields survive because nobody types the delimiter. Turning it
      # on has to be a call site's decision, made next to the model that can take
      # it back.
      def numeric_options(method, options)
        opts = options.with_defaults(
          placeholder: 0,
          inputmode: "decimal",
          pattern_type: :localized_number
        )

        opts[:delimited] ? delimited_number_options(method, opts) : opts
      end

      def numeric_addon(symbol)
        tag.span(symbol, class: HtmlUtils::ADDON_CLASSES)
      end
    end
  end
end
