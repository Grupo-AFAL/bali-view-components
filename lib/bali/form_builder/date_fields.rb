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

      def month_field_group(method, options = {})
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          month_field(method, options)
        end
      end

      def month_field(method, options = {})
        field_helper(method, super(method, field_options(method, options)), options)
      end
    end
  end
end
