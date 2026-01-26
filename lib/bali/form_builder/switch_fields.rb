# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SwitchFields
      TOGGLE_CLASS = 'toggle'
      LABEL_CLASS = 'label cursor-pointer gap-3'
      LABEL_TEXT_CLASS = 'label-text'
      ERROR_CLASS = 'label-text-alt text-error'
      FIELDSET_CLASS = 'fieldset'

      SIZES = {
        xs: 'toggle-xs',
        sm: 'toggle-sm',
        md: 'toggle-md',
        lg: 'toggle-lg'
      }.freeze

      COLORS = {
        primary: 'toggle-primary',
        secondary: 'toggle-secondary',
        accent: 'toggle-accent',
        success: 'toggle-success',
        warning: 'toggle-warning',
        info: 'toggle-info',
        error: 'toggle-error'
      }.freeze

      def switch_field_group(method, options = {}, checked_value = '1', unchecked_value = '0')
        @template.content_tag(:fieldset, class: FIELDSET_CLASS) do
          switch_field(method, options, checked_value, unchecked_value)
        end
      end

      def switch_field(method, options = {}, checked_value = '1', unchecked_value = '0')
        label_text = extract_switch_label_text(method, options)
        label_options = extract_switch_label_options(options)
        toggle_options = build_toggle_options(method, options)

        label_html = label(method, label_options) do
          safe_join([
                      content_tag(:span, label_text, class: LABEL_TEXT_CLASS),
                      check_box(method, toggle_options, checked_value, unchecked_value)
                    ], ' ')
        end

        append_switch_error_message(method, label_html)
      end

      private

      def extract_switch_label_text(method, options)
        options.delete(:label) || translate_attribute(method)
      end

      def extract_switch_label_options(options)
        base_options = options.delete(:label_options) || {}
        custom_class = base_options[:class]
        base_options[:class] = [LABEL_CLASS, custom_class].compact.join(' ')
        base_options
      end

      def build_toggle_options(method, options)
        size = options.delete(:size)
        color = options.delete(:color)
        custom_class = options.delete(:class)

        toggle_class = [
          TOGGLE_CLASS,
          SIZES[size],
          COLORS[color],
          (errors?(method) ? 'toggle-error' : nil),
          custom_class
        ].compact.join(' ')

        options.merge(class: toggle_class)
      end

      def append_switch_error_message(method, html)
        return html unless errors?(method)

        html + content_tag(:p, full_errors(method), class: ERROR_CLASS)
      end
    end
  end
end
