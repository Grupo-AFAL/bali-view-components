# frozen_string_literal: true

module Bali
  module Frame
    # Un `<turbo-frame>` con carga diferida y swap a un placeholder mientras carga.
    #
    # Turbo marca el `<turbo-frame>` con `[busy]` durante CUALQUIER carga: la
    # diferida inicial (`loading: :lazy` con `src`) y cada recarga dirigida al
    # frame —incluido un link con `data-turbo-frame` apuntando aquí, o un botón
    # de "Refrescar"—. Mientras está `[busy]`, el CSS co-localizado muestra la
    # card hermana `.frame-loading` y oculta el frame: el contenido se reemplaza
    # por el indicador de carga y vuelve al terminar. Puro CSS, sin JS.
    #
    # Diferido (el `src` trae el contenido; el placeholder se ve mientras llega):
    #
    #   <%= render Bali::Frame::Component.new(
    #         id: "report", src: report_path, loading: :lazy, text: "Consultando…") %>
    #
    # Con contenido propio (el bloque es el contenido del frame; el placeholder
    # aparece al recargar el frame):
    #
    #   <%= render Bali::Frame::Component.new(id: "report") do %>
    #     <table>…</table>
    #   <% end %>
    #
    # Placeholder a medida (una card, un skeleton) vía el slot `loading`:
    #
    #   <%= render Bali::Frame::Component.new(id: "report", src: report_path) do |frame| %>
    #     <% frame.with_loading do %><%= render Bali::Skeleton::Component.new %><% end %>
    #   <% end %>
    class Component < ApplicationViewComponent
      renders_one :loading

      # @param id [String] id del turbo-frame (obligatorio)
      # @param src [String, nil] URL para carga diferida
      # @param loading [Symbol, String, nil] estrategia de carga del frame (:lazy, :eager)
      # @param text [String, nil] texto junto al spinner del placeholder por default
      def initialize(id:, src: nil, loading: nil, text: nil, **options)
        @id = id
        @src = src
        @loading = loading
        @text = text
        @options = options
      end

      private

      attr_reader :options

      def wrapper_attributes
        options.except(:class).merge(class: class_names("frame-loader", options[:class]))
      end

      def frame_attributes
        { id: @id, src: @src, loading: @loading }.compact
      end

      # Placeholder por default: spinner chico + texto, centrado y atenuado. Se
      # usa en la card hermana y como contenido inicial de un frame diferido,
      # salvo que el host pase su propio slot `loading`.
      def default_loading
        tag.div(class: "flex items-center justify-center gap-2 py-6 text-sm text-base-content/60") do
          safe_join([ tag.span(class: "loading loading-spinner loading-sm"), display_text ])
        end
      end

      def display_text
        @text || I18n.t("bali_view.frame.loading")
      end
    end
  end
end
