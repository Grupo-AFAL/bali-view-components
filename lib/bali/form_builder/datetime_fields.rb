# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module DatetimeFields
      DATETIME_WRAPPER_OPTIONS = {
        'data-datepicker-enable-time-value': true
      }.freeze

      def datetime_group(method, **options)
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          datetime_field(method, options)
        end
      end

      # Takes `time_field`'s time options as well: `time_24hr:`, `seconds:`, `min_time:`, …
      def datetime_field(method, options = {})
        date_field(method, options.merge(wrapper_options: merged_time_options(DATETIME_WRAPPER_OPTIONS, options)))
      end
    end
  end
end
