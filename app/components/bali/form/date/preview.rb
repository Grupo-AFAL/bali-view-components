# frozen_string_literal: true

module Bali
  module Form
    module Date
      class Preview < ApplicationViewComponentPreview
        def default
          render_with_template(
            template: 'bali/form/date/default',
            locals: { model: form_record }
          )
        end

        def min_date
          render_with_template(
            template: 'bali/form/date/min_date',
            locals: { model: form_record }
          )
        end

        def date_range
          render_with_template(
            template: 'bali/form/date/range',
            locals: { model: form_record }
          )
        end

        def with_controls
          render_with_template(
            template: 'bali/form/date/with_controls',
            locals: { model: form_record }
          )
        end

        def weekends_disabled
          render_with_template(
            template: 'bali/form/date/weekends_disabled',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
