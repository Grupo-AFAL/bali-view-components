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
