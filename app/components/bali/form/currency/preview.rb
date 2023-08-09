# frozen_string_literal: true

module Bali
  module Form
    module Currency
      class Preview < ApplicationViewComponentPreview
        def default
          render_with_template(
            template: 'bali/form/currency/previews/default',
            locals: { model: form_record }
          )
        end

        def with_errors
          form_record.errors.add(:currency, :invalid)

          render_with_template(
            template: 'bali/form/currency/previews/with_errors',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
