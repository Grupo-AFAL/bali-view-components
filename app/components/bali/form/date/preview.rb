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

        # Typing is allowed (`allow_input: true`) and paired with an explicit
        # `alt_format: 'd/m/Y'`, so Bali auto-fills `placeholder="dd/mm/yyyy"` —
        # a hint at what the field will actually parse on blur.
        def allow_input
          render_with_template(
            template: 'bali/form/date/previews/allow_input',
            locals: { model: form_record }
          )
        end

        # Same as above, but with no explicit `alt_format:` — the field falls
        # back to the verbose default format, so the auto-filled placeholder
        # comes from an i18n string instead of a token-mapped hint.
        def allow_input_default_format
          render_with_template(
            template: 'bali/form/date/previews/allow_input_default_format',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
