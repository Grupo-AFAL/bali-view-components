# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module CoordinatesPolygonFields
      def coordinates_polygon_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          coordinates_polygon_field(method, options)
        end
      end

      def coordinates_polygon_field(method, options = {})
        options = setup_options(options)
        value = options.delete(:value) || []
        value = value.to_json unless value.is_a?(String)

        tag.div(**options) do
          safe_join(
            [
              tag.div(class: 'map', style: 'height: 400px', data: { drawing_maps_target: 'map' }),
              hidden_field(method, value: value, data: { drawing_maps_target: 'polygonField' })
            ]
          )
        end
      end

      private

      def setup_options(opts)
        opts = prepend_controller(opts, 'drawing-maps')
        prepend_data_attribute(opts, 'drawing-maps-key', ENV.fetch('GOOGLE_MAPS_KEY', ''))
      end
    end
  end
end
