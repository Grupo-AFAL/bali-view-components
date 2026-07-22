# frozen_string_literal: true

module Bali
  module EmptyState
    class Preview < ApplicationViewComponentPreview
      # Icon in a soft circle + title + description.
      # @param size [Symbol] select [sm, md, lg]
      def default(size: :md)
        render EmptyState::Component.new(
          title: "Sin iniciativas",
          description: "Aún no hay iniciativas registradas en esta etapa.",
          icon: "inbox",
          size: size
        )
      end

      # With a call-to-action rendered through the `cta` slot.
      def with_cta
        render_with_template
      end

      # Text-only (no icon), compact size for cells and panels.
      def without_icon
        render EmptyState::Component.new(
          title: "Sin resultados",
          description: "Ajusta los filtros para ver más resultados.",
          size: :sm
        )
      end

      # Title only — the minimum useful empty state.
      def title_only
        render EmptyState::Component.new(title: "Nada por aquí")
      end
    end
  end
end
