# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TimeFields
      def time_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          time_field(method, options)
        end
      end

      def time_field(method, options = {})
        options[:wrapper_options] = {
          'data-datepicker-enable-time-value': true,
          'data-datepicker-no-calendar-value': true
        }

        enable_seconds(options)
        datepicker_default_date(options)
        datepicker_min_time(options)
        datepicker_max_time(options)

        value = object.send(method)

        # Adds a date if already doesn't include one (it will detect the date by an empty space),
        # so that the time_field_group can display its time value correctly
        options[:value] = [Date.current, value].join(' ') unless value.include?(' ')

        date_field(method, options)
      end

      private

      def enable_seconds(options)
        return unless options[:seconds]

        options[:wrapper_options].merge!('data-datepicker-enable-seconds-value': true)
      end

      def datepicker_default_date(options)
        return if options[:default_date].blank?

        options[:wrapper_options].merge!(
          'data-datepicker-default-date-value': options[:default_date]
        )
      end

      def datepicker_min_time(options)
        return if options[:min_time].blank?

        options[:wrapper_options].merge!(
          'data-datepicker-min-time-value': options[:min_time]
        )
      end

      def datepicker_max_time(options)
        return if options[:max_time].blank?

        options[:wrapper_options].merge!(
          'data-datepicker-max-time-value': options[:max_time]
        )
      end
    end
  end
end
