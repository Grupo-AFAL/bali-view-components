# frozen_string_literal: true

module Bali
  module Frame
    class Preview < ApplicationViewComponentPreview
      # Frame con contenido propio: el bloque es el contenido del frame. El
      # placeholder de carga aparece cuando algo recarga el frame (un link con
      # `data-turbo-frame` apuntando aquí, o un botón de "Refrescar").
      # @param text text
      def default(text: "Cargando…")
        render Frame::Component.new(id: "frame-preview-default", text: text) do
          "Contenido cargado del frame."
        end
      end

      # @label Loading state
      # El placeholder que se ve mientras el frame está `[busy]` —la primera carga
      # diferida o una recarga dirigida al frame—. Aquí se fuerza `[busy]` para
      # verlo sin un backend que responda el `src`.
      def loading_state
        render_with_template
      end
    end
  end
end
