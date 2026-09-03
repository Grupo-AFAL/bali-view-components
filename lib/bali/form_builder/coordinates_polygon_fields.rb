# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module CoordinatesPolygonFields
      BUTTON_CLASSES = {
        clear_holes: "btn btn-ghost mr-4",
        clear_all: "btn btn-ghost text-error"
      }.freeze

      MAP_CLASSES = "map h-[400px]"
      BUTTON_WRAPPER_CLASSES = "flex justify-end items-center mb-3"

      # The caption stays a `<legend>`: the only form control here is a hidden
      # field the map writes into, and a hidden input is not labelable.
      def coordinates_polygon_group(method, **options)
        @template.render Bali::FieldGroupWrapper::Component.new(
          self, method, options.merge(control_id: false)
        ) do
          coordinates_polygon_field(method, options)
        end
      end

      def coordinates_polygon_field(method, options = {})
        value = serialize_value(options.fetch(:value, []))
        attributes = setup_options(widget_attributes(dup_options(options)).except(:value))

        tag.div(**attributes) do
          safe_join(
            [
              clear_buttons,
              tag.div(class: MAP_CLASSES, data: { drawing_maps_target: "map" }),
              hidden_field(method, polygon_field_options(options, value))
            ]
          )
        end
      end

      private

      # `input_name:` names the hidden field the map writes into — the only control
      # this family submits. Not `input_id:`: the caption is a `<legend>` here
      # (`control_id: false`), so there is nothing pointing at an id to keep honest.
      def polygon_field_options(options, value)
        attributes = { value: value, data: { drawing_maps_target: "polygonField" } }
        attributes[:name] = options[:input_name] if options[:input_name]
        attributes
      end

      def serialize_value(value)
        value.is_a?(String) ? value : value.to_json
      end

      def setup_options(opts)
        opts = prepend_controller(opts, "drawing-maps")
        opts = prepend_data_attribute(
          opts,
          "drawing-maps-confirmation-message-to-clear-value",
          I18n.t("bali_view.form_builder.coordinates_polygon.confirm")
        )
        prepend_data_attribute(opts, "drawing-maps-key", Bali.google_maps_key.to_s)
      end

      def clear_buttons
        tag.div(class: BUTTON_WRAPPER_CLASSES) do
          safe_join([ clear_holes_button, clear_all_button ])
        end
      end

      def clear_holes_button
        tag.button(
          I18n.t("bali_view.form_builder.coordinates_polygon.clear_holes"),
          type: "button",
          class: BUTTON_CLASSES[:clear_holes],
          data: { action: "drawing-maps#clearHoles" }
        )
      end

      def clear_all_button
        tag.button(
          I18n.t("bali_view.form_builder.coordinates_polygon.clear"),
          type: "button",
          class: BUTTON_CLASSES[:clear_all],
          data: { action: "drawing-maps#clear" }
        )
      end
    end
  end
end
