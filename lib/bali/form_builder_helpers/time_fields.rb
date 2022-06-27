# frozen_string_literal: true

module Bali
  module FormBuilderHelpers
    module TimeFields
      def time_field_group(method, options = {})
        FieldGroupWrapper.render @template, self, method, options do
          time_field(method, options)
        end
      end

      def time_field(method, options = {})
        options[:wrapper_options] = {
          'data-datepicker-enable-time-value': true,
          'data-datepicker-no-calendar-value': true
        }

        if options[:seconds]
          options[:wrapper_options].merge!(
            'data-datepicker-enable-seconds-value': true
          )
        end

        if options[:default_date].present?
          options[:wrapper_options].merge!(
            'data-datepicker-default-date-value': options[:default_date]
          )
        end

        if options[:min_time].present?
          options[:wrapper_options].merge!(
            'data-datepicker-min-time-value': options[:min_time]
          )
        end

        if options[:max_time].present?
          options[:wrapper_options].merge!(
            'data-datepicker-max-time-value': options[:max_time]
          )
        end

        value = object.send(method)

        # Adds a date if already doesn't include one (it will detect the date by an empty space),
        # so that the time_field_group can display its time value correctly
        options[:value] = [Date.current, value].join(' ') unless value.include?(' ')

        date_field(method, options)
      end
    end
  end
end
