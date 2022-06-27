# frozen_string_literal: true

module Bali
  module FormBuilderHelpers
    module SelectFields
      def select_group(method, values, options = {}, html_options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          select_field(method, values, options, html_options)
        end
      end

      # Uses the native HTML <select> element.
      #
      def select_field(method, values, options = {}, html_options = {})
        select_class = field_class_name(method, "select #{html_options.delete(:select_class)}")
        select_data = html_options.delete(:select_data)
        select_id = "#{method}_select_div"

        field = content_tag(:div, id: select_id, class: select_class, data: select_data) do
          select(method, values, options, html_options.except(:control_data, :control_class))
        end

        field_helper(method, field, field_options(method, html_options))
      end
    end
  end
end
