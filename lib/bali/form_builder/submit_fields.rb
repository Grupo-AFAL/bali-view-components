# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SubmitFields
      def submit(value, options = {})
        options.with_defaults!(
          wrapper_class: 'inline',
          data: {},
          type: 'submit',
          class: 'btn btn-primary'
        )

        unless Bali.native_app
          options = prepend_action(options, 'modal#submit') if options.delete(:modal)

          options = prepend_action(options, 'drawer#submit') if options.delete(:drawer)
        end

        content_tag(:div, class: options.delete(:wrapper_class)) do
          content_tag(:button, value, options)
        end
      end

      # TODO: Fix these lint warning
      #
      #
      def submit_actions(value, options = {})
        cancel = cancel_button(
          options.delete(:cancel_path), options.delete(:cancel_options),
          modal: options[:modal], drawer: options[:drawer]
        )

        field_data = options.delete(:field_data)
        field_id = options.delete(:field_id)
        field_class = options.delete(:field_class) ||
                      'submit-actions field is-grouped is-grouped-right'

        submit = @template.content_tag(:div, class: 'control') do
          submit(value, options)
        end

        render_cancel_button = cancel.present? && !(Bali.native_app && options[:modal])
        @template.content_tag(:div, id: field_id, class: field_class, data: field_data) do
          render_cancel_button ? cancel + submit : submit
        end
      end

      private

      def cancel_button(path = nil, options = nil, modal: false, drawer: false)
        return unless path.present? || options.present? || modal || drawer

        options ||= {}
        options = prepend_action(options, 'modal#close') if modal
        options = prepend_action(options, 'drawer#close') if drawer

        options.with_defaults!(class: 'btn btn-secondary')
        @template.content_tag(:div, class: 'control') do
          @template.link_to(cancel_button_label(options), path, options)
        end
      end

      def cancel_button_label(options)
        options.delete(:label) || I18n.t('helpers.cancel.text', default: 'Cancel')
      end
    end
  end
end
