# frozen_string_literal: true

module Bali
  module FormBuilderHelpers
    module DatetimeFields
      def datetime_field_group(method, options = {})
        FieldGroupWrapper.render @template, self, method, options do
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
