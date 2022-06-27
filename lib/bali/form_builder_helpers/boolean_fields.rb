module Bali
  module FormBuilderHelpers
    module BooleanFields
      def boolean_field_group(method, options = {}, checked_value = '1', unchecked_value = '0')
        @template.content_tag(:div, class: 'field') do
          boolean_field(method, options, checked_value, unchecked_value)
        end
      end

      alias check_box_group boolean_field_group

      def boolean_field(method, options = {}, checked_value = '1', unchecked_value = '0')
        label_text = options.delete(:label) || translate_attribute(method)

        label(method, options.delete(:label_options) || {}) do
          safe_join([check_box(method, options, checked_value, unchecked_value), label_text], ' ')
        end
      end
    end
  end
end