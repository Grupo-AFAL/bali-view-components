# frozen_string_literal: true

module Bali
  module Form
    module Percentage
      class Preview < ApplicationViewComponentPreview
        # @param symbol select { choices: [%, ‰, pp] }
        def default(symbol: '%')
          render_with_template(
            template: 'bali/form/percentage/previews/default',
            locals: { model: form_record, symbol: symbol }
          )
        end

        def with_errors
          form_record.errors.add(:budget, :invalid)

          render_with_template(
            template: 'bali/form/percentage/previews/default',
            locals: { model: form_record, symbol: '%' }
          )
        end
      end
    end
  end
end
