module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TimePeriodFields
      def time_period_field_group(method, select_options, value: nil, **options)
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          time_period_field(method, select_options, value: value, **options)
        end
      end

      def time_period_field(method, select_options, value: nil, **options)
        value ||= object.try(method)
        include_blank = options.key?(:include_blank) ? options.delete(:include_blank) : ''

        tag.div(class: 'is-flex', data: { controller: 'time-period-field' }) do
          safe_join(
            [
              text_field(method, value: value, data: { time_period_field_target: 'input' }),
              time_periods_select(method, select_options, value, include_blank),
              time_periods_date_field(method)
            ]
          )
        end
      end

      private

      def time_periods_select(method, select_options, value, include_blank)
        select_options = Array.wrap(select_options)
        select_options << [include_blank, ''] if include_blank

        selected = select_options.find { |_, time_period| time_period == value }&.last
        selected ||= '' unless value.nil?

        tag.div(class: 'control') do
          tag.div(class: 'select') do
            @template.select_tag(
              "#{method}_period", @template.options_for_select(select_options, selected),
              data: {
                time_period_field_target: 'select',
                action: 'time-period-field#toggleDateInput time-period-field#setInputValue'
              }
            )
          end
        end
      end

      def time_periods_date_field(method)
        date_field(
          "#{method}_date_range",
          mode: 'range', alt_input: false, label: false, class: 'is-hidden',
          value: Time.zone.now.all_day,
          data: { time_period_field_target: 'dateInput', action: 'time-period-field#setInputValue' }
        )
      end
    end
  end
end
