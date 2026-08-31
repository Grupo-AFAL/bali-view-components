# frozen_string_literal: true

module Bali
  module Form
    module Currency
      class Preview < ApplicationViewComponentPreview
        # @param symbol select { choices: [$, €, £, ¥] }
        def default(symbol: '$')
          render_with_template(
            template: 'bali/form/currency/previews/default',
            locals: { model: form_record, symbol: symbol }
          )
        end

        # @label Delimited (live thousands separator)
        # `delimited: true` groups the thousands on every keystroke. It is opt-in
        # because the delimiter changes what the field SUBMITS: a grouped amount
        # only survives the trip if the model carries `currency_attribute` from
        # `Bali::Concerns::NumericAttributesWithCommas`. Without it Rails casts
        # `"1,500,200"` to 1.
        def delimited(symbol: '$')
          render_with_template(
            template: 'bali/form/currency/previews/delimited',
            locals: { model: form_record, symbol: symbol }
          )
        end

        # @label Delimited, with a stored amount
        # The half that is not visible while typing: the value is grouped by the
        # SERVER, in the locale of the request, so a stored amount reads the same
        # as one just typed. Deciding that in the browser is not decidable —
        # `1.500` is a machine number in English and a delimited fifteen hundred
        # in Spanish, and each reading corrupts the other.
        def with_value
          form_record.currency = 1_500_200.75

          render_with_template(
            template: 'bali/form/currency/previews/delimited',
            locals: { model: form_record, symbol: '$' }
          )
        end

        def with_errors
          form_record.errors.add(:currency, :invalid)

          render_with_template(
            template: 'bali/form/currency/previews/default',
            locals: { model: form_record, symbol: '$' }
          )
        end
      end
    end
  end
end
