# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RadioFields
      def radio_field_group(method, values, options = {}, html_options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          radio_field(method, values, options, html_options)
        end
      end

      def radio_field(method, values, options = {}, html_options = {})
        label_class = class_names(['radio', html_options.delete(:radio_label_class)])

        field = @template.safe_join(tags(values, html_options, method, label_class))
        field_helper(method, field, options)
      end

      def radio_buttons_grouped(method, values, options = {}, _html_options = {})
        options = prepend_controller(options, 'radio-toggle')
        options = prepend_data_attribute(options, 'radio-toggle-current-value', values.keys.first)
        options = prepend_class_name(options, 'control')

        tag.div(**options) do
          safe_join([
                      buttons(values),
                      radio_options(method, values)
                    ])
        end
      end

      private

      def tags(values, html_options, method, label_class)
        field_name = [object.model_name.singular, method].join('_')
        data = html_options.delete(:data)

        values.map do |display_value|
          display, value, radio_options = display_value
          radio_options ||= {}
          radio_options.merge!(html_options)

          label(method, class: label_class, for: [field_name, value].join('_')) do
            radio_button(method, value, radio_options.merge(data: data)) + display
          end
        end
      end

      def buttons(values)
        safe_join(values.keys.map do |v|
          tag.button(v, type: 'button', disabled: values[v].blank?,
                        data: { action: 'radio-toggle#change' },
                        value: v)
        end)
      end

      def radio_options(method, values)
        tag.div(class: 'mb-6') do
          safe_join(values.map do |key, value|
            tag.div(data: { 'radio-toggle-target': 'element', 'radio-toggle-value': key }) do
              radio_field method, value
            end
          end)
        end
      end
    end
  end
end
