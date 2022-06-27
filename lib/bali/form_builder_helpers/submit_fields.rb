# frozen_string_literal: true

module Bali
  module FormBuilderHelpers
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
      # rubocop:disable Metrics/CyclomaticComplexity
      #
      def submit_actions(value, options = {})
        cancel_path = options.delete(:cancel_path) || ''
        cancel_options = options.delete(:cancel_options) || {}

        field_data = options.delete(:field_data)
        field_id = options.delete(:field_id)
        field_class = options.delete(:field_class) || 'field is-grouped is-grouped-right'

        cancel_options = prepend_action(cancel_options, 'modal#close') if options[:modal]

        cancel_options = prepend_action(cancel_options, 'drawer#close') if options[:drawer]

        @template.content_tag(:div, id: field_id, class: field_class, data: field_data) do
          submit = @template.content_tag(:div, class: 'control') do
            submit(value, options)
          end

          if cancel_path.present? || cancel_options.present?
            cancel_label = cancel_options.delete(:label) || I18n.t(:cancel, default: 'Cancel')
            cancel_options.with_defaults!(class: 'button is-secondary')
            cancel = @template.content_tag(:div, class: 'control') do
              @template.link_to(cancel_label, cancel_path, cancel_options)
            end

            cancel + submit
          else
            submit
          end
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
