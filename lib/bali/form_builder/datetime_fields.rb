# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module DatetimeFields
      DATETIME_WRAPPER_OPTIONS = {
        'data-datepicker-enable-time-value': true
      }.freeze

      def datetime_field_group(method, options = {})
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          datetime_field(method, options)
        end
      end

      alias datetime_select_group datetime_field_group

      def datetime_field(method, options = {})
        merged_wrapper_options = DATETIME_WRAPPER_OPTIONS.merge(options[:wrapper_options] || {})
        date_field(method, options.merge(wrapper_options: merged_wrapper_options))
      end
    end
  end
end
