# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TimePeriodFields
      CONTROLLER_NAME = "time-period-field"
      SELECT_CLASSES = "select select-bordered w-full"
      SELECT_WRAPPER_CLASSES = "mb-2"
      DATE_FIELD_HIDDEN_CLASS = "hidden"

      # The caption names the period select, not the hidden field the controller
      # writes the resolved range into: the select is the control the user
      # operates, and a hidden input is not labelable anyway.
      def time_period_group(method, select_options, selected: nil, **options)
        @template.render(
          Bali::FieldGroupWrapper::Component.new(
            self, method, options.merge(control_id: period_select_id(method))
          )
        ) do
          time_period_field(method, select_options, selected: selected, **options)
        end
      end

      def time_period_field(method, select_options, selected: nil, **options)
        include_blank = options.fetch(:include_blank, "")
        wrapper_attrs = time_period_wrapper_attrs(options)
        selected_value = selected || object.try(method)

        final_select_options = build_select_options(select_options, include_blank)
        is_custom = custom_date_range?(select_options, selected_value)

        tag.div(**wrapper_attrs) do
          safe_join([
                      hidden_field(method, value: selected_value,
                                           data: { "#{CONTROLLER_NAME}-target": "input" }),
                      time_periods_select(method, final_select_options,
                                          is_custom ? "" : selected_value),
                      time_periods_date_field(method, is_custom ? selected_value : nil)
                    ])
        end
      end

      private

      def time_period_wrapper_attrs(options)
        prepend_controller(
          html_attributes(dup_options(options)).except(:include_blank),
          CONTROLLER_NAME
        )
      end

      def build_select_options(select_options, include_blank)
        return select_options if include_blank.blank?

        select_options + [ [ include_blank, "" ] ]
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
            id: period_select_id(method),
            class: SELECT_CLASSES,
            data: select_data_attributes
          )
        end
      end

      # `select_tag` derives its id from the name, so this used to be a bare
      # `created_at_period`: no object name, no index, and therefore the same id
      # twice as soon as two forms for the same model share a page. Only the id
      # changes — the name is left alone in case a host reads it.
      def period_select_id(method)
        field_id(method, "period")
      end

      def select_data_attributes
        {
          "#{CONTROLLER_NAME}-target": "select",
          action: "#{CONTROLLER_NAME}#toggleDateInput #{CONTROLLER_NAME}#setInputValue"
        }
      end

      def time_periods_date_field(method, value)
        date_field(
          "#{method}_date_range",
          mode: "range",
          alt_input: false,
          label: false,
          class: DATE_FIELD_HIDDEN_CLASS,
          value: value.presence || Time.zone.now.all_day,
          data: date_field_data_attributes
        )
      end

      def date_field_data_attributes
        {
          "#{CONTROLLER_NAME}-target": "dateInput",
          action: "#{CONTROLLER_NAME}#setInputValue"
        }
      end
    end
  end
end
