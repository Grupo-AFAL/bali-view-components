# frozen_string_literal: true

module Bali
  module FormBuilderHelpers
    module TextAreaFields
      def text_area_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          text_area(method, options)
        end
      end

      def text_area(method, options = {})
        options[:class] = field_class_name(method, "textarea #{options[:class]}")

        field_helper(method, super(method, options), options)
      end
    end
  end
end
