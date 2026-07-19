# frozen_string_literal: true

module Bali
  module Status
    class Preview < ApplicationViewComponentPreview
      STATUSES = [
        { value: "pending", label: "Pendiente", color: :slate },
        { value: "in_review", label: "En revisión", color: :blue },
        { value: "in_progress", label: "En proceso", color: :amber },
        { value: "ready", label: "Listo para revisión", color: :orange },
        { value: "done", label: "Completada", color: :green },
        { value: "paused", label: "Pausada", color: :gray },
        { value: "cancelled", label: "Cancelada", color: :red }
      ].freeze

      # Read-only pill (no form).
      # @param selected [Symbol] select [pending, in_review, in_progress, ready, done, paused, cancelled]
      # @param size [Symbol] select [xs, sm, md]
      def default(selected: :in_progress, size: :sm)
        render Status::Component.new(selected: selected, options: STATUSES, size: size)
      end

      # Editable pill: click opens the colored panel; selecting submits the form.
      # @param size [Symbol] select [xs, sm, md]
      # @param clearable toggle
      def editable(size: :sm, clearable: true)
        render Status::Component.new(
          selected: "in_progress",
          options: STATUSES,
          form: { url: "/lookbook", method: :patch, param: "thing[status]" },
          clearable: clearable,
          size: size
        )
      end

      # None / unassigned state.
      def no_status
        render Status::Component.new(selected: nil, options: STATUSES)
      end

      # Hex-color escape hatch (color outside the named palette).
      def custom_color
        render Status::Component.new(
          selected: "brand",
          options: [{ value: "brand", label: "Brand", color: "#7c3aed" }]
        )
      end

      # Full named palette gallery.
      def palette
        render_with_template(locals: {
          swatches: Bali::Status::Component::PALETTE.keys
        })
      end

      # Editable pill inside an overflow-x container (proves the panel is not clipped).
      def in_table
        render_with_template
      end
    end
  end
end
