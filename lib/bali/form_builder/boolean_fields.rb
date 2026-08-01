# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module BooleanFields
      CHECKBOX_CLASS = "checkbox"
      LABEL_CLASS = "label cursor-pointer"

      # Consumed here rather than forwarded: `size` and `color` name daisyUI
      # variants in this family, so unlike on a text input they are not the HTML
      # attributes of the same name.
      CHECKBOX_OPTIONS = %i[label_options size color].freeze

      SIZES = {
        xs: "checkbox-xs",
        sm: "checkbox-sm",
        md: "checkbox-md",
        lg: "checkbox-lg"
      }.freeze

      COLORS = {
        primary: "checkbox-primary",
        secondary: "checkbox-secondary",
        accent: "checkbox-accent",
        success: "checkbox-success",
        warning: "checkbox-warning",
        info: "checkbox-info",
        error: "checkbox-error"
      }.freeze

      def boolean_field_group(method, options = {}, checked_value = "1", unchecked_value = "0")
        @template.render Bali::FieldGroupWrapper::Component.new(self, method, options) do
          boolean_field(method, options, checked_value, unchecked_value)
        end
      end

      alias check_box_group boolean_field_group

      def boolean_field(method, options = {}, checked_value = "1", unchecked_value = "0")
        label_text = options[:label] || translate_attribute(method)
        label_options = build_label_options(options)
        checkbox_options = build_checkbox_options(method, options)

        label_html = label(method, label_options) do
          safe_join([
                      check_box(method, checkbox_options, checked_value, unchecked_value),
                      content_tag(:span, label_text)
                    ], " ")
        end

        label_html + error_and_help(method, options)
      end

      private

      def build_label_options(options)
        base_options = options[:label_options] || {}

        base_options.merge(class: [ LABEL_CLASS, base_options[:class] ].compact.join(" "))
      end

      def build_checkbox_options(method, options)
        checkbox_class = [
          CHECKBOX_CLASS,
          SIZES[options[:size]],
          COLORS[options[:color]],
          (errors?(method) ? "checkbox-error" : nil),
          options[:class]
        ].compact.join(" ")

        html_attributes(options).except(*CHECKBOX_OPTIONS).merge(class: checkbox_class)
      end
    end
  end
end
