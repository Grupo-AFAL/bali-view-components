# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module BooleanFields
      def boolean_field_group(method, options = {}, checked_value = '1', unchecked_value = '0')
        @template.content_tag(:div, class: 'field') do
          boolean_field(method, options, checked_value, unchecked_value)
        end
      end

      alias check_box_group boolean_field_group

      def boolean_field(method, options = {}, checked_value = '1', unchecked_value = '0')
        label_text = options.delete(:label) || translate_attribute(method)

        label_html = label(method, options.delete(:label_options) || {}) do
          safe_join([check_box(method, options, checked_value, unchecked_value), label_text], ' ')
        end

        if errors?(method)
          label_html + content_tag(:p, full_errors(method), class: 'label-text-alt text-error')
        else
          label_html
        end
      end
    end
  end
end
