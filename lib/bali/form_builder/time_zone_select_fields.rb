# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TimeZoneSelectFields
      # DaisyUI select classes matching SelectFields pattern
      BASE_CLASSES = "select select-bordered w-full"

      def time_zone_select_group(method, priority_zones = nil, options = {}, html_options = {})
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          time_zone_select(method, priority_zones, options, html_options)
        end
      end

      def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
        attributes = time_zone_html_options(method, html_options)
        field = super(method, priority_zones, options, attributes)

        field_helper(method, field, html_options)
      end

      private

      def time_zone_html_options(method, html_options)
        base = field_class_name(method, BASE_CLASSES, error_class: "select-error")

        attributes = html_attributes(html_options).except(:class).merge(
          class: [ base, html_options[:class] ].compact.join(" ")
        )

        merge_aria_attributes(attributes, method, html_options)
      end
    end
  end
end
