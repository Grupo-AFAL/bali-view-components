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

      def radio_buttons_grouped(method, values, options = {}, buttons_options = {}, radios_options = {})
        options[:control_data] ||= {}
        options[:control_data].merge!(controller: 'radio-toggle',
                                      'radio-toggle-current-value': values.keys.first)

        field = safe_join([buttons(values, buttons_options), radio_options(method, values, radios_options)])
        field_helper(method, field, options)
      end

      private

      def buttons(values, options)
        button_options = options.delete(:button) || {}
        button_options = prepend_action(button_options, 'radio-toggle#change')
        button_options[:type] = 'button'

        tag.div(**options) do
          safe_join(values.keys.map do |value|
            button_options[:disabled] = values[value].blank?
            button_options[:value] = value
            
            tag.button(value, **button_options)
          end)
        end
      end

      def radio_options(method, values, options)
        options = prepend_data_attribute(options, 'radio-toggle-target', 'element')

        label_options = options.delete(:label) || {}
        label_options = prepend_class_name(label_options, 'radio')

        safe_join(values.map do |key, valuez|
          options[:data]['radio-toggle-value'] = key

          tag.div(**options) do
            safe_join(tags(valuez, {}, method, label_options[:class]))
          end
        end)
      end

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
    end
  end
end
