# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SubmitFields
      BUTTON_BASE_CLASS = 'btn'
      WRAPPER_CLASS = 'inline'
      SUBMIT_ACTIONS_CLASS = 'submit-actions flex items-center justify-end gap-2'

      VARIANTS = {
        primary: 'btn-primary',
        secondary: 'btn-secondary',
        accent: 'btn-accent',
        success: 'btn-success',
        warning: 'btn-warning',
        error: 'btn-error',
        ghost: 'btn-ghost'
      }.freeze

      SIZES = {
        xs: 'btn-xs',
        sm: 'btn-sm',
        md: nil,
        lg: 'btn-lg'
      }.freeze

      def submit(value, options = {})
        variant = options.delete(:variant) || :primary
        size = options.delete(:size)
        wrapper_class = options.delete(:wrapper_class) || WRAPPER_CLASS

        options.with_defaults!(
          type: 'submit',
          class: button_classes(variant: variant, size: size, custom_class: options.delete(:class))
        )

        options = apply_stimulus_actions(options)

        content_tag(:div, class: wrapper_class) do
          content_tag(:button, value, options)
        end
      end

      def submit_actions(value, options = {})
        cancel_config = extract_cancel_config(options)
        wrapper_config = extract_wrapper_config(options)

        cancel_html = build_cancel_button(cancel_config)
        submit_html = submit(value, options)

        should_render_cancel = cancel_html.present? && show_cancel_button?(options)

        content_tag(:div, wrapper_config) do
          should_render_cancel ? safe_join([cancel_html, submit_html]) : submit_html
        end
      end

      private

      def button_classes(variant:, size: nil, custom_class: nil)
        [
          BUTTON_BASE_CLASS,
          VARIANTS[variant],
          SIZES[size],
          custom_class
        ].compact.join(' ')
      end

      def apply_stimulus_actions(options)
        return options if Bali.native_app

        options = prepend_action(options, 'modal#submit') if options.delete(:modal)
        options = prepend_action(options, 'drawer#submit') if options.delete(:drawer)
        options
      end

      def extract_cancel_config(options)
        {
          path: options.delete(:cancel_path),
          options: options.delete(:cancel_options),
          modal: options[:modal],
          drawer: options[:drawer]
        }
      end

      def extract_wrapper_config(options)
        {
          id: options.delete(:field_id),
          class: options.delete(:field_class) || SUBMIT_ACTIONS_CLASS,
          data: options.delete(:field_data)
        }.compact
      end

      def build_cancel_button(config)
        return unless cancel_button_required?(config)

        link_options = build_cancel_link_options(config)
        label = link_options.delete(:label) || I18n.t('helpers.cancel.text', default: 'Cancel')

        content_tag(:div, class: WRAPPER_CLASS) do
          if config[:path].present?
            @template.link_to(label, config[:path], link_options)
          else
            # When no path, use a button for modal/drawer close actions
            content_tag(:button, label, link_options.merge(type: 'button'))
          end
        end
      end

      def cancel_button_required?(config)
        config[:path].present? || config[:options].present? ||
          config[:modal] || config[:drawer]
      end

      def build_cancel_link_options(config)
        link_options = config[:options] || {}
        link_options = prepend_action(link_options, 'modal#close') if config[:modal]
        link_options = prepend_action(link_options, 'drawer#close') if config[:drawer]
        link_options.with_defaults!(class: button_classes(variant: :secondary))
        link_options
      end

      def show_cancel_button?(options)
        !(Bali.native_app && options[:modal])
      end
    end
  end
end
