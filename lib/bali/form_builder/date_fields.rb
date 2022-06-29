# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module DateFields
      def date_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          date_field(method, options)
        end
      end

      alias date_select_group date_field_group
    end
  end
end
