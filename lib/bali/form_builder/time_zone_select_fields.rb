# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module TimeZoneSelectFields
      # DaisyUI select classes matching SelectFields pattern
      BASE_CLASSES = 'select select-bordered w-full'

      def time_zone_select_group(method, priority_zones = nil, options = {}, html_options = {})
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          time_zone_select(method, priority_zones, options, html_options)
        end
      end

      def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
        merged_options = time_zone_html_options(method, html_options)
        field = super(method, priority_zones, options, merged_options)

        field_helper(method, field, extract_help_options(html_options))
      end

      private

      def time_zone_html_options(method, html_options)
        custom_class = html_options[:class]
        base = field_class_name(method, BASE_CLASSES)

        html_options.except(:class, :control_data, :control_class, :help).merge(
          class: [base, custom_class].compact.join(' ')
        )
      end

      def extract_help_options(html_options)
        {
          help: html_options[:help],
          control_data: html_options[:control_data],
          control_class: html_options[:control_class]
        }
      end
    end
  end
end
