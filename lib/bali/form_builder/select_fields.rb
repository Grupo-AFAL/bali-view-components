# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SelectFields
      # DaisyUI base classes for select elements
      BASE_CLASSES = "select select-bordered w-full"

      def select_group(method, values, options = {}, html_options = {})
        @template.render Bali::FieldGroupWrapper::Component.new(self, method, options) do
          select_field(method, values, options, html_options)
        end
      end

      # Uses the native HTML <select> element with DaisyUI styling.
      def select_field(method, values, options = {}, html_options = {})
        attributes = html_attributes(html_options)
        attributes[:class] = select_classes(method, html_options[:class])
        apply_input_name_options(options, attributes)

        field = select(method, values, options, attributes)
        field_helper(method, field, html_options)
      end

      private

      def select_classes(method, additional_classes = nil)
        base = field_class_name(method, BASE_CLASSES, error_class: "select-error")
        [ base, additional_classes ].compact.join(" ")
      end
    end
  end
end
