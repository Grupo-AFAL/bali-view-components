# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TimeZoneSelectFields
      # DaisyUI select classes matching SelectFields pattern
      BASE_CLASSES = "select select-bordered w-full"

      def time_zone_select_group(method, priority_zones = nil, options = {}, html_options = {})
        group = group_options(options, html_options)

        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, group)) do
          time_zone_select(method, priority_zones, options, html_options)
        end
      end

      def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
        group = group_options(options, html_options)
        attributes = time_zone_html_options(method, html_options, group)
        field = super(method, priority_zones, options, attributes)

        field_helper(method, field, group)
      end

      private

      # `group` and not `html_options`: `aria_attributes` decides whether to emit
      # `aria-describedby` by looking for `help:`, so reading the hash that does
      # not carry it points the control at nothing while the paragraph renders
      # anyway — a description that exists on screen and not in the a11y tree.
      def time_zone_html_options(method, html_options, group = html_options)
        base = field_class_name(method, BASE_CLASSES, error_class: "select-error")

        attributes = html_attributes(html_options).except(:class).merge(
          class: [ base, html_options[:class] ].compact.join(" ")
        )

        merge_aria_attributes(attributes, method, group)
      end
    end
  end
end
