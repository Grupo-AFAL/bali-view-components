# frozen_string_literal: true

module Bali
  module Form
    module Time
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Time picker with calendar disabled and time enabled.
        # Uses Flatpickr with `enableTime: true` and `noCalendar: true`.
        def default
          render_with_template(
            template: 'bali/form/time/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Seconds
        # Time picker that includes seconds selection.
        # Pass `seconds: true` to enable seconds input.
        def with_seconds
          render_with_template(
            template: 'bali/form/time/previews/with_seconds',
            locals: { model: form_record }
          )
        end

        # @label With Min/Max Time
        # Time picker with minimum and maximum time constraints.
        # Use `min_time:` and `max_time:` options to set boundaries.
        def with_constraints
          render_with_template(
            template: 'bali/form/time/previews/with_constraints',
            locals: { model: form_record }
          )
        end

        # @label With Initial Value
        # Time field pre-populated with a value.
        def with_value
          record = form_record
          record.time = 36_000 # 10:00:00 in seconds
          render_with_template(
            template: 'bali/form/time/previews/default',
            locals: { model: record }
          )
        end

        # @label 24-Hour Format
        # Time picker using 24-hour format (e.g., 14:30 instead of 2:30 PM).
        # Pass `time_24hr: true` to enable.
        def time_24hr
          render_with_template(
            template: 'bali/form/time/previews/time_24hr',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
