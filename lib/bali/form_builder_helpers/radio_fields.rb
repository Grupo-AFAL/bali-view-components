# frozen_string_literal: true

module Bali
  module FormBuilderHelpers
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
    end
  end
end
