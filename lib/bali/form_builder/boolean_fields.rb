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

      # Two captions, two keys. `text:` is the one beside the checkbox — how a
      # checkbox is normally named, and where its accessible name comes from.
      # `label:` is the `<legend>` naming the group around it.
      #
      # Only `text:` has a default. A single `label:` used to feed both, so the
      # attribute name came out twice — once as the legend, once beside the box —
      # and the field read out "Indie Indie". The legend now renders only when
      # the caller asks for one, which is when a group caption says something
      # the inline text does not.
      #
      # That caption stays a `<legend>` even then: `boolean_field` wraps the
      # checkbox in a `<label>` of its own, and a second `<label for>` on the
      # same control does not replace that name, it concatenates with it.
      def boolean_field_group(method, options = {}, checked_value = "1", unchecked_value = "0")
        @template.render Bali::FieldGroupWrapper::Component.new(
          self, method, options.merge(control_id: false, label: options.fetch(:label, false))
        ) do
          boolean_field(method, options, checked_value, unchecked_value)
        end
      end

      alias check_box_group boolean_field_group

      def boolean_field(method, options = {}, checked_value = "1", unchecked_value = "0")
        label_options = build_label_options(options)
        checkbox_options = build_checkbox_options(method, options)

        label_html = label(method, label_options) do
          safe_join([
                      check_box(method, checkbox_options, checked_value, unchecked_value),
                      inline_caption(method, options)
                    ].compact, " ")
        end

        label_html + error_and_help(method, options)
      end

      private

      # No `for`. The label wraps the checkbox, so the implicit association names
      # it, and that association cannot be broken the way an explicit `for` can:
      # a `for` binds to whichever element in the document happens to carry the
      # id first, so the moment the same attribute is rendered twice — or the
      # caller passes an `id:` of their own — every checkbox after the first was
      # left with no accessible name at all.
      def build_label_options(options)
        base_options = options[:label_options] || {}

        base_options.reverse_merge(for: nil)
                    .merge(class: [ LABEL_CLASS, base_options[:class] ].compact.join(" "))
      end

      def build_checkbox_options(method, options)
        checkbox_class = [
          CHECKBOX_CLASS,
          SIZES[options[:size]],
          COLORS[options[:color]],
          (errors?(method) ? "checkbox-error" : nil),
          options[:class]
        ].compact.join(" ")

        attributes = html_attributes(options).except(*CHECKBOX_OPTIONS)
                                             .merge(class: checkbox_class)

        merge_aria_attributes(attributes, method, options)
      end
    end
  end
end
