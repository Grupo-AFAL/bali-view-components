module Bali
  module FormBuilderHelpers
    module RadioFields
      def radio_field_group(method, values, options = {}, html_options = {})
        FieldGroupWrapper.render @template, self, method, options do
          radio_field(method, values, options, html_options)
        end
      end

      def radio_field(method, values, options = {}, html_options = {})
        field_name = [object.model_name.singular, method].join('_')
        data = html_options.delete(:data)
        label_class = class_names(['radio', html_options.delete(:radio_label_class)])

        tags = values.map do |display_value|
          display, value, radio_options = display_value
          radio_options ||= {}
          radio_options.merge!(html_options)

          label(method, class: label_class, for: [field_name, value].join('_')) do
            radio_button(method, value, radio_options.merge(data: data)) + display
          end
        end

        field = @template.safe_join(tags)
        field_helper(method, field, options)
      end
    end
  end
end