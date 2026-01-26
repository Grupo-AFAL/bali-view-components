# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module CoordinatesPolygonFields
      BUTTON_CLASSES = {
        clear_holes: 'btn btn-ghost mr-4',
        clear_all: 'btn btn-ghost text-error'
      }.freeze

      MAP_CLASSES = 'map h-[400px]'
      BUTTON_WRAPPER_CLASSES = 'flex justify-end items-center mb-3'

      def coordinates_polygon_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new(self, method, options) do
          coordinates_polygon_field(method, options)
        end
      end

      def coordinates_polygon_field(method, options = {})
        options = setup_options(options)
        value = serialize_value(options.fetch(:value, []))
        options = options.except(:value)

        tag.div(**options) do
          safe_join(
            [
              clear_buttons,
              tag.div(class: MAP_CLASSES, data: { drawing_maps_target: 'map' }),
              hidden_field(method, value: value, data: { drawing_maps_target: 'polygonField' })
            ]
          )
        end
      end

      private

      def serialize_value(value)
        value.is_a?(String) ? value : value.to_json
      end

      def setup_options(opts)
        opts = prepend_controller(opts, 'drawing-maps')
        opts = prepend_data_attribute(
          opts,
          'drawing-maps-confirmation-message-to-clear-value',
          I18n.t('helpers.generic_confirm_message.text')
        )
        prepend_data_attribute(opts, 'drawing-maps-key', google_maps_key)
      end

      def google_maps_key
        ENV.fetch('GOOGLE_MAPS_KEY', '')
      end

      def clear_buttons
        tag.div(class: BUTTON_WRAPPER_CLASSES) do
          safe_join([clear_holes_button, clear_all_button])
        end
      end

      def clear_holes_button
        tag.button(
          I18n.t('helpers.clear_holes.text'),
          type: 'button',
          class: BUTTON_CLASSES[:clear_holes],
          data: { action: 'drawing-maps#clearHoles' }
        )
      end

      def clear_all_button
        tag.button(
          I18n.t('helpers.clear.text'),
          type: 'button',
          class: BUTTON_CLASSES[:clear_all],
          data: { action: 'drawing-maps#clear' }
        )
      end
    end
  end
end
