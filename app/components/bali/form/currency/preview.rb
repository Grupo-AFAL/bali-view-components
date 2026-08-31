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

        # @label With a stored amount
        # The typing side of the delimiter is visible in every scenario on this
        # page. This one shows the other half: the value reaches the browser as
        # the machine number `1500200.75` — always a dot, whatever the locale —
        # and is grouped on connect, so a stored amount reads the same as one
        # just typed.
        def with_value
          form_record.currency = 1_500_200.75

          render_with_template(
            template: 'bali/form/currency/previews/default',
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
