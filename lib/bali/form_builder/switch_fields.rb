# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SwitchFields
      TOGGLE_CLASS = "toggle"
      LABEL_CLASS = "label cursor-pointer gap-3"
      FIELDSET_CLASS = "fieldset"

      # Consumed here rather than forwarded: `size` and `color` name daisyUI
      # variants in this family, so unlike on a text input they are not the HTML
      # attributes of the same name.
      TOGGLE_OPTIONS = %i[label_options size color].freeze

      SIZES = {
        xs: "toggle-xs",
        sm: "toggle-sm",
        md: "toggle-md",
        lg: "toggle-lg"
      }.freeze

      COLORS = {
        primary: "toggle-primary",
        secondary: "toggle-secondary",
        accent: "toggle-accent",
        success: "toggle-success",
        warning: "toggle-warning",
        info: "toggle-info",
        error: "toggle-error"
      }.freeze

      def switch_field_group(method, options = {}, checked_value = "1", unchecked_value = "0")
        @template.content_tag(:fieldset, class: FIELDSET_CLASS) do
          switch_field(method, options, checked_value, unchecked_value)
        end
      end

      def switch_field(method, options = {}, checked_value = "1", unchecked_value = "0")
        label_text = options[:label] || translate_attribute(method)
        label_options = build_switch_label_options(options)
        toggle_options = build_toggle_options(method, options)

        label_html = label(method, label_options) do
          safe_join([
                      content_tag(:span, label_text),
                      check_box(method, toggle_options, checked_value, unchecked_value)
                    ], " ")
        end

        label_html + error_and_help(method, options)
      end

      private

      # No `for`, for the same reason as BooleanFields: the label wraps the
      # toggle, so the implicit association names it and survives both a repeated
      # attribute and a caller-supplied `id:`, neither of which an explicit `for`
      # survives.
      def build_switch_label_options(options)
        base_options = options[:label_options] || {}

        base_options.reverse_merge(for: nil)
                    .merge(class: [ LABEL_CLASS, base_options[:class] ].compact.join(" "))
      end

      def build_toggle_options(method, options)
        toggle_class = [
          TOGGLE_CLASS,
          SIZES[options[:size]],
          COLORS[options[:color]],
          (errors?(method) ? "toggle-error" : nil),
          options[:class]
        ].compact.join(" ")

        attributes = html_attributes(options).except(*TOGGLE_OPTIONS).merge(class: toggle_class)

        merge_aria_attributes(attributes, method, options)
      end
    end
  end
end
