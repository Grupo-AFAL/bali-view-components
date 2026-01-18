# frozen_string_literal: true

module Bali
  module SearchInput
    class Component < ApplicationViewComponent
      BASE_INPUT_CLASSES = 'input input-bordered'
      BASE_BUTTON_CLASSES = 'btn btn-primary join-item'
      CONTAINER_CLASS = 'search-input-component w-full'

      def initialize(form:, field:, auto_submit: false, placeholder: nil, **options)
        @form = form
        @field = field
        @auto_submit = auto_submit
        @placeholder = placeholder
        @options = options
      end

      private

      attr_reader :form, :field, :auto_submit, :placeholder, :options

      def value
        form.public_send(field)
      end

      def input_id
        "#{form.model_name}_#{field}"
      end

      def input_name
        "#{form.model_name}[#{field}]"
      end

      def input_classes
        class_names(BASE_INPUT_CLASSES, options[:class])
      end

      def container_classes
        class_names('form-control', show_submit_button? && 'join')
      end

      def control_classes
        class_names('flex-1', show_submit_button? && 'join-item')
      end

      def button_classes
        class_names(BASE_BUTTON_CLASSES, submit_options[:class])
      end

      def button_attributes
        submit_options.except(:class)
      end

      def input_data
        return {} unless auto_submit

        { action: 'submit-on-change#submit' }
      end

      def show_submit_button?
        !auto_submit
      end

      def resolved_placeholder
        placeholder || t('.placeholder')
      end

      def submit_options
        @submit_options ||= options.fetch(:submit, {})
      end
    end
  end
end
