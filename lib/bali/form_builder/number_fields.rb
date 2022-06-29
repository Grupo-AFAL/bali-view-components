# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module NumberFields
      def number_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          number_field(method, options)
        end
      end
    end
  end
end
