# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TimePeriodFields
      CONTROLLER_NAME = 'time-period-field'
      SELECT_CLASSES = 'select select-bordered w-full'
      SELECT_WRAPPER_CLASSES = 'mb-2'
      DATE_FIELD_HIDDEN_CLASS = 'hidden'

      def time_period_field_group(method, select_options, selected: nil, **options)
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          time_period_field(method, select_options, selected: selected, **options)
        end
      end

      def time_period_field(method, select_options, selected: nil, **options)
        include_blank = options.fetch(:include_blank, '')
        wrapper_attrs = time_period_wrapper_options(options)
        selected_value = selected || object.try(method)

        final_select_options = build_select_options(select_options, include_blank)
        is_custom = custom_date_range?(select_options, selected_value)

        tag.div(**wrapper_attrs) do
          safe_join([
                      hidden_field(method, value: selected_value,
                                           data: { "#{CONTROLLER_NAME}-target": 'input' }),
                      time_periods_select(method, final_select_options,
                                          is_custom ? '' : selected_value),
                      time_periods_date_field(method, is_custom ? selected_value : nil)
                    ])
        end
      end

      private

      def time_period_wrapper_options(options)
        prepend_controller(
          options.except(:include_blank),
          CONTROLLER_NAME
        )
      end

      def build_select_options(select_options, include_blank)
        return select_options if include_blank.blank?

        select_options + [[include_blank, '']]
      end

      def custom_date_range?(select_options, selected)
        return false if selected.blank?

        select_options.none? { |_, range| range.to_s == selected.to_s }
      end

      def time_periods_select(method, select_options, selected_value)
        tag.div(class: SELECT_WRAPPER_CLASSES) do
          @template.select_tag(
            "#{method}_period",
            @template.options_for_select(select_options, selected_value),
            class: SELECT_CLASSES,
            data: select_data_attributes
          )
        end
      end

      def select_data_attributes
        {
          "#{CONTROLLER_NAME}-target": 'select',
          action: "#{CONTROLLER_NAME}#toggleDateInput #{CONTROLLER_NAME}#setInputValue"
        }
      end

      def time_periods_date_field(method, value)
        date_field(
          "#{method}_date_range",
          mode: 'range',
          alt_input: false,
          label: false,
          class: DATE_FIELD_HIDDEN_CLASS,
          value: value.presence || Time.zone.now.all_day,
          data: date_field_data_attributes
        )
      end

      def date_field_data_attributes
        {
          "#{CONTROLLER_NAME}-target": 'dateInput',
          action: "#{CONTROLLER_NAME}#setInputValue"
        }
      end
    end
  end
end
