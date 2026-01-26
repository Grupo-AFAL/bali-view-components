# frozen_string_literal: true

module Bali
  module Form
    module TimeZoneSelect
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Time zone selector using Rails' `time_zone_select` helper with DaisyUI styling.
        # Uses `select select-bordered w-full` classes.
        def default
          render_with_template(
            template: 'bali/form/time_zone_select/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Priority Zones
        # Shows US time zones first, then all other time zones below.
        # Useful for applications primarily serving US users.
        def with_priority_zones
          render_with_template(
            template: 'bali/form/time_zone_select/previews/with_priority_zones',
            locals: { model: form_record }
          )
        end

        # @label With Errors
        # Shows validation error styling with `input-error` class.
        def with_errors
          form_record.errors.add(:time_zone, 'must be selected')

          render_with_template(
            template: 'bali/form/time_zone_select/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Help Text
        # Displays helper text below the time zone selector.
        def with_help_text
          render_with_template(
            template: 'bali/form/time_zone_select/previews/with_help_text',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
