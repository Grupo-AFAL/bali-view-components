# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SubmitFields
      BUTTON_BASE_CLASS = "btn"
      WRAPPER_CLASS = "inline"
      SUBMIT_ACTIONS_CLASS = "submit-actions flex items-center justify-end gap-2 mt-6"

      VARIANTS = {
        primary: "btn-primary",
        secondary: "btn-secondary",
        accent: "btn-accent",
        success: "btn-success",
        warning: "btn-warning",
        error: "btn-error",
        ghost: "btn-ghost"
      }.freeze

      SIZES = {
        xs: "btn-xs",
        sm: "btn-sm",
        md: nil,
        lg: "btn-lg"
      }.freeze

      # Everything `submit` and `submit_actions` read for themselves: the button
      # styling, the Stimulus wiring and the cancel button beside it. None of them
      # is an attribute of the <button> that comes out the other end.
      SUBMIT_OPTIONS = %i[
        variant size wrapper_class class modal drawer
        cancel_path cancel_options field_id field_class field_data
      ].freeze

      def submit(value, options = {})
        wrapper_class = options[:wrapper_class] || WRAPPER_CLASS

        attributes = html_attributes(options).except(*SUBMIT_OPTIONS).with_defaults(
          type: "submit",
          class: button_classes(
            variant: options[:variant] || :primary,
            size: options[:size],
            custom_class: options[:class]
          )
        )
        attributes = apply_stimulus_actions(options, dup_options(attributes))

        content_tag(:div, class: wrapper_class) do
          content_tag(:button, value, attributes)
        end
      end

      def submit_actions(value, options = {})
        cancel_config = extract_cancel_config(options)
        wrapper_config = extract_wrapper_config(options)

        cancel_html = build_cancel_button(cancel_config)
        submit_html = submit(value, options)

        should_render_cancel = cancel_html.present? && show_cancel_button?(options)

        content_tag(:div, wrapper_config) do
          should_render_cancel ? safe_join([ cancel_html, submit_html ]) : submit_html
        end
      end

      private

      def button_classes(variant:, size: nil, custom_class: nil)
        [
          BUTTON_BASE_CLASS,
          VARIANTS[variant],
          SIZES[size],
          custom_class
        ].compact.join(" ")
      end

      def apply_stimulus_actions(options, attributes)
        return attributes if Bali.native_app

        attributes = prepend_action(attributes, "modal#submit") if options[:modal]
        attributes = prepend_action(attributes, "drawer#submit") if options[:drawer]
        attributes
      end

      def extract_cancel_config(options)
        {
          path: options[:cancel_path],
          options: options[:cancel_options],
          modal: options[:modal],
          drawer: options[:drawer]
        }
      end

      def extract_wrapper_config(options)
        {
          id: options[:field_id],
          class: options[:field_class] || SUBMIT_ACTIONS_CLASS,
          data: options[:field_data]
        }.compact
      end

      def build_cancel_button(config)
        return unless cancel_button_required?(config)

        link_options = build_cancel_link_options(config)
        label = config.dig(:options, :label) || I18n.t("bali_view.form_builder.submit.cancel")

        content_tag(:div, class: WRAPPER_CLASS) do
          if config[:path].present?
            @template.link_to(label, config[:path], link_options)
          else
            # When no path, use a button for modal/drawer close actions
            content_tag(:button, label, link_options.merge(type: "button"))
          end
        end
      end

      def cancel_button_required?(config)
        config[:path].present? || config[:options].present? ||
          config[:modal] || config[:drawer]
      end

      def build_cancel_link_options(config)
        link_options = dup_options(config[:options] || {}).except(:label)
        link_options = prepend_action(link_options, "modal#close") if config[:modal]
        link_options = prepend_action(link_options, "drawer#close") if config[:drawer]
        link_options.with_defaults(class: button_classes(variant: :secondary))
      end

      def show_cancel_button?(options)
        !(Bali.native_app && options[:modal])
      end
    end
  end
end
