# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TextAreaFields
      def text_area_group(method, options = {})
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          text_area(method, options)
        end
      end

      def text_area(method, options = {})
        field_helper(method, super(method, textarea_field_options(method, options)), options)
      end
    end
  end
end
