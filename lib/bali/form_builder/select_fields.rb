# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SelectFields
      # DaisyUI base classes for select elements
      BASE_CLASSES = 'select select-bordered w-full'

      def select_group(method, values, options = {}, html_options = {})
        @template.render Bali::FieldGroupWrapper::Component.new(self, method, options) do
          select_field(method, values, options, html_options)
        end
      end

      # Uses the native HTML <select> element with DaisyUI styling.
      def select_field(method, values, options = {}, html_options = {})
        html_options[:class] = select_classes(method, html_options[:class])

        field = select(method, values, options, html_options.except(:control_data, :control_class))
        field_helper(method, field, select_field_options(method, html_options))
      end

      private

      def select_classes(method, additional_classes = nil)
        base = field_class_name(method, BASE_CLASSES)
        [base, additional_classes].compact.join(' ')
      end

      def select_field_options(_method, html_options)
        {
          control_data: html_options[:control_data],
          control_class: html_options[:control_class],
          help: html_options[:help]
        }
      end
    end
  end
end
