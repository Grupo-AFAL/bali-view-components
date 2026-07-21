# frozen_string_literal: true

module Bali
  module Form
    module Date
      class Preview < ApplicationViewComponentPreview
        # Date fields are typeable by default — users can pick from the calendar
        # or type directly. Bali auto-fills a `placeholder="dd/mm/yyyy"` hint
        # derived from the default numeric display format (`d/m/Y`).
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

        # Typing is enabled by default now, so `allow_input: true` is redundant
        # here — it's shown for reference. Pairing it with an explicit
        # `alt_format: 'd/m/Y'` pins the display/typed format, and Bali auto-fills
        # the matching `placeholder="dd/mm/yyyy"` hint.
        def allow_input
          render_with_template(
            template: 'bali/form/date/previews/allow_input',
            locals: { model: form_record }
          )
        end

        # With no explicit `alt_format:`, the placeholder is derived from the
        # default numeric format via token mapping — `dd/mm/yyyy` — the same hint
        # the `default` variant now shows.
        def allow_input_default_format
          render_with_template(
            template: 'bali/form/date/previews/allow_input_default_format',
            locals: { model: form_record }
          )
        end

        # Opt out of typing with `allow_input: false`: the field becomes
        # read-only (flatpickr keeps its `readonly` attribute) and no placeholder
        # is set — users must pick a value from the calendar.
        def readonly_opt_out
          render_with_template(
            template: 'bali/form/date/previews/readonly_opt_out',
            locals: { model: form_record }
          )
        end

      end
    end
  end
end
