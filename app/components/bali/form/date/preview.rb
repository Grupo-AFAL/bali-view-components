# frozen_string_literal: true

module Bali
  module Form
    module Date
      class Preview < ApplicationViewComponentPreview
        def default
          render_with_template(
            template: 'bali/form/date/previews/default',
            locals: { model: form_record }
          )
        end

        def min_date
          render_with_template(
            template: 'bali/form/date/previews/min_date',
            locals: { model: form_record }
          )
        end

        def date_range
          render_with_template(
            template: 'bali/form/date/previews/range',
            locals: { model: form_record }
          )
        end

        def with_controls
          render_with_template(
            template: 'bali/form/date/previews/with_controls',
            locals: { model: form_record }
          )
        end

        def with_tooltip
          render_with_template(
            template: 'bali/form/date/previews/with_tooltip',
            locals: { model: form_record }
          )
        end

        def weekends_disabled
          render_with_template(
            template: 'bali/form/date/previews/weekends_disabled',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
