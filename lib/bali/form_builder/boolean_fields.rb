# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module BooleanFields
      CHECKBOX_CLASS = 'checkbox'
      LABEL_CLASS = 'label cursor-pointer'
      LABEL_TEXT_CLASS = 'label-text'
      ERROR_CLASS = 'label-text-alt text-error'

      SIZES = {
        xs: 'checkbox-xs',
        sm: 'checkbox-sm',
        md: 'checkbox-md',
        lg: 'checkbox-lg'
      }.freeze

      COLORS = {
        primary: 'checkbox-primary',
        secondary: 'checkbox-secondary',
        accent: 'checkbox-accent',
        success: 'checkbox-success',
        warning: 'checkbox-warning',
        info: 'checkbox-info',
        error: 'checkbox-error'
      }.freeze

      def boolean_field_group(method, options = {}, checked_value = '1', unchecked_value = '0')
        @template.render Bali::FieldGroupWrapper::Component.new(self, method, options) do
          boolean_field(method, options, checked_value, unchecked_value)
        end
      end

      alias check_box_group boolean_field_group

      def boolean_field(method, options = {}, checked_value = '1', unchecked_value = '0')
        label_text = extract_label_text(method, options)
        label_options = extract_label_options(options)
        checkbox_options = build_checkbox_options(method, options)

        label_html = label(method, label_options) do
          safe_join([
                      check_box(method, checkbox_options, checked_value, unchecked_value),
                      content_tag(:span, label_text, class: LABEL_TEXT_CLASS)
                    ], ' ')
        end

        append_error_message(method, label_html)
      end

      private

      def extract_label_text(method, options)
        options.delete(:label) || translate_attribute(method)
      end

      def extract_label_options(options)
        base_options = options.delete(:label_options) || {}
        custom_class = base_options[:class]
        base_options[:class] = [LABEL_CLASS, custom_class].compact.join(' ')
        base_options
      end

      def build_checkbox_options(method, options)
        size = options.delete(:size)
        color = options.delete(:color)
        custom_class = options.delete(:class)

        checkbox_class = [
          CHECKBOX_CLASS,
          SIZES[size],
          COLORS[color],
          (errors?(method) ? 'checkbox-error' : nil),
          custom_class
        ].compact.join(' ')

        options.merge(class: checkbox_class)
      end

      def append_error_message(method, html)
        return html unless errors?(method)

        html + content_tag(:p, full_errors(method), class: ERROR_CLASS)
      end
    end
  end
end
