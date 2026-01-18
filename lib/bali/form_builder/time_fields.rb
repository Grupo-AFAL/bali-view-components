# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TimeFields
      TIME_WRAPPER_OPTIONS = {
        'data-datepicker-enable-time-value': true,
        'data-datepicker-no-calendar-value': true
      }.freeze

      OPTION_TO_DATA_ATTRIBUTE = {
        seconds: 'data-datepicker-enable-seconds-value',
        default_date: 'data-datepicker-default-date-value',
        min_time: 'data-datepicker-min-time-value',
        max_time: 'data-datepicker-max-time-value'
      }.freeze

      def time_field_group(method, options = {})
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          time_field(method, options)
        end
      end

      def time_field(method, options = {})
        merged_options = options.merge(
          wrapper_options: merged_time_options(options),
          value: formatted_time_value(method, options[:value])
        )

        date_field(method, merged_options)
      end

      private

      def merged_time_options(options)
        base_options = TIME_WRAPPER_OPTIONS.merge(options[:wrapper_options] || {})

        OPTION_TO_DATA_ATTRIBUTE.each_with_object(base_options.dup) do |(key, attr), result|
          result[attr] = options[key] if options[key].present?
        end
      end

      def formatted_time_value(method, explicit_value)
        value = explicit_value || object&.public_send(method)
        return nil if value.blank?

        formatted = value.respond_to?(:strftime) ? value.strftime('%H:%M:%S') : value.to_s

        # Flatpickr requires a date component for time-only fields
        formatted.include?(' ') ? formatted : "#{Date.current} #{formatted}"
      end
    end
  end
end
