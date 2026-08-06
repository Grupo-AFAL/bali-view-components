# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SwitchFields
      TOGGLE_CLASS = "toggle"
      LABEL_CLASS = "label cursor-pointer gap-3"

      # Consumed here rather than forwarded: `size` and `color` name daisyUI
      # variants in this family, so unlike on a text input they are not the HTML
      # attributes of the same name.
      TOGGLE_OPTIONS = %i[label_options size color].freeze

      SIZES = {
        xs: "toggle-xs",
        sm: "toggle-sm",
        md: "toggle-md",
        lg: "toggle-lg",
        xl: "toggle-xl"
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

      # Through FieldGroupWrapper like every other group, which is where the
      # fieldset's id, its `w-full` and the `tooltip:`/`label: false` handling
      # come from — a hand-rolled `<fieldset class="fieldset">` had none of them,
      # so two toggles for the same model on one page shared no id at all and
      # the group could not be captioned.
      #
      # Same split as BooleanFields: `text:` beside the toggle, `label:` as the
      # `<legend>`, and no legend unless asked for.
      #
      # `checked_value:` / `unchecked_value:` are keywords for the same reason as
      # in BooleanFields.
      def switch_group(method, checked_value: "1", unchecked_value: "0", **options)
        @template.render Bali::FieldGroupWrapper::Component.new(
          self, method, options.merge(control_id: false, label: options.fetch(:label, false))
        ) do
          switch_field(
            method, checked_value: checked_value, unchecked_value: unchecked_value, **options
          )
        end
      end

      def switch_field(method, checked_value: "1", unchecked_value: "0", **options)
        label_options = build_switch_label_options(options)
        toggle_options = build_toggle_options(method, options)

        label_html = label(method, label_options) do
          safe_join([
                      inline_caption(method, options),
                      check_box(method, toggle_options, checked_value, unchecked_value)
                    ].compact, " ")
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
          size_variant(options, SIZES),
          COLORS[options[:color]],
          (errors?(method, options) ? "toggle-error" : nil),
          options[:class]
        ].compact.join(" ")

        attributes = html_attributes(options).except(*TOGGLE_OPTIONS).merge(class: toggle_class)

        merge_aria_attributes(attributes, method, options)
      end
    end
  end
end
