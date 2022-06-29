# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TextFields
      def text_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          text_field(method, options)
        end
      end
    end
  end
end
