# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SubmitFields
      def submit(value, options = {})
        options.with_defaults!(
          wrapper_class: 'inline',
          data: {},
          type: 'submit',
          class: 'button is-primary'
        )

        options = prepend_action(options, 'modal#submit') if options.delete(:modal)

        options = prepend_action(options, 'drawer#submit') if options.delete(:drawer)

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
        field_class = options.delete(:field_class) || 'field is-grouped is-grouped-right'

        submit = @template.content_tag(:div, class: 'control') do
          submit(value, options)
        end

        @template.content_tag(:div, id: field_id, class: field_class, data: field_data) do
          cancel.present? ? cancel + submit : submit
        end
      end

      private

      def cancel_button(path = nil, options = nil, modal: true, drawer: false)
        return unless path.present? || options.present?

        options ||= {}
        options = prepend_action(options, 'modal#close') if modal
        options = prepend_action(options, 'drawer#close') if drawer
        label = options.delete(:label) || I18n.t(:cancel, default: 'Cancel')

        options.with_defaults!(class: 'button is-secondary')
        @template.content_tag(:div, class: 'control') do
          @template.link_to(label, path, options)
        end
      end
    end
  end
end
