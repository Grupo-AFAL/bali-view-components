# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module DatetimeFields
      def datetime_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          datetime_field(method, options)
        end
      end

      alias datetime_select_group datetime_field_group

      def datetime_field(method, options = {})
        options[:wrapper_options] = { 'data-datepicker-enable-time-value': true }
        date_field(method, options)
      end
    end
  end
end
