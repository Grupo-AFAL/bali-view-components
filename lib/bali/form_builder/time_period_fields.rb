# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TimePeriodFields
      def time_period_field_group(method, select_options, selected: nil, **options)
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          time_period_field(method, select_options, selected: selected, **options)
        end
      end

      def time_period_field(method, select_options, selected: nil, **options)
        include_blank = options.key?(:include_blank) ? options.delete(:include_blank) : ''
        options = prepend_controller(options, 'time-period-field')

        select_options = Array.wrap(select_options)
        select_options << [include_blank, ''] if include_blank

        selected ||= object.try(method)
        custom = select_options.find { |_, range| range.to_s == selected.to_s }.blank?

        tag.div(**options) do
          safe_join(
            [
              hidden_field(method, value: selected, data: { time_period_field_target: 'input' }),
              time_periods_select(method, select_options, custom ? '' : selected),
              time_periods_date_field(method, custom ? selected : nil)
            ]
          )
        end
      end

      private

      def time_periods_select(method, select_options, selected_value)
        tag.div(class: 'control mb-2') do
          tag.div(class: 'select') do
            @template.select_tag(
              "#{method}_period", @template.options_for_select(select_options, selected_value),
              data: {
                time_period_field_target: 'select',
                action: 'time-period-field#toggleDateInput time-period-field#setInputValue'
              }
            )
          end
        end
      end

      def time_periods_date_field(method, value)
        date_field(
          "#{method}_date_range",
          mode: 'range', alt_input: false, label: false, class: 'is-hidden',
          value: value.presence || Time.zone.now.all_day,
          data: { time_period_field_target: 'dateInput', action: 'time-period-field#setInputValue' }
        )
      end
    end
  end
end
