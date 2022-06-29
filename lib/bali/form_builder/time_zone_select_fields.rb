# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TimeZoneSelectFields
      def time_zone_select_group(method, priority_zones = nil, options = {}, html_options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          time_zone_select(method, priority_zones, options, html_options)
        end
      end

      def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
        select_class = field_class_name(method, "select #{html_options.delete(:select_class)}")

        field = content_tag(:div, class: select_class) do
          super(method, priority_zones, options, field_options(method, html_options))
        end

        field_helper(method, field, options)
      end
    end
  end
end
