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

        # @label Delimited (live thousands separator)
        # Opt-in, like every family: the delimiter changes what the field submits,
        # and a grouped value only survives the trip with `percentage_attribute`
        # from `Bali::Concerns::NumericAttributesWithCommas` on the model.
        def delimited(symbol: '%')
          render_with_template(
            template: 'bali/form/percentage/previews/delimited',
            locals: { model: form_record, symbol: symbol }
          )
        end

        def with_errors
          form_record.errors.add(:percentage, :invalid)

          render_with_template(
            template: 'bali/form/percentage/previews/default',
            locals: { model: form_record, symbol: '%' }
          )
        end
      end
    end
  end
end
