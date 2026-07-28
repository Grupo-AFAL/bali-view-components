# frozen_string_literal: true

module Bali
  module DataTable
    module SavedViews
      # Dropdown "Vistas" del DataTable (B2): aplicar, guardar la actual, renombrar y borrar
      # combinaciones de filtros con nombre. El storage NO vive aquí: el FilterForm trae un
      # `saved_views_store` (solo lectura) y las mutaciones se POSTean a la URL de la app
      # (`url:`) — create en `url`, update/delete en `url/:id` (rutas RESTful de la app).
      #
      # `default_views:` son atajos ESTÁTICOS (no persistidos) que la app define — pares
      # {name:, url:} listos para navegar; se pintan en su propia sección "Sugeridas".
      class Component < ApplicationViewComponent
        DefaultView = Struct.new(:name, :url, keyword_init: true)

        # @param filter_form [Bali::FilterForm] con saved_views_store configurado
        # @param url [String] base RESTful de la app para crear/renombrar/borrar vistas
        # @param base_url [String] URL del listado donde se aplican (?saved_view=<id>)
        # @param table_id [String] id de la tabla (para capturar columnas visibles al guardar)
        # @param default_views [Array<Hash>] atajos estáticos {name:, url:}
        def initialize(filter_form:, url:, base_url:, table_id: nil, default_views: nil)
          @filter_form = filter_form
          @url = url
          @base_url = base_url.to_s
          @table_id = table_id && (table_id.start_with?("#") ? table_id : "##{table_id}")
          @default_views = Array(default_views).map { |view| DefaultView.new(**view.to_h.symbolize_keys) }
        end

        attr_reader :filter_form, :url, :table_id, :default_views

        # Sin URL no hay mutaciones posibles (pasa cuando el slot no recibió `url:` y el
        # form no tiene storage_id para armar la default del engine): no pintar nada gana
        # sobre pintar forms rotos.
        def render?
          filter_form&.saved_views_enabled? && url.present?
        end

        def views
          filter_form.saved_views
        end

        def current_view
          filter_form.current_saved_view
        end

        def apply_url(view)
          "#{@base_url}#{@base_url.include?('?') ? '&' : '?'}saved_view=#{view.id}"
        end

        # El id se inserta en el PATH (no al final de la URL cruda): una `url` con query
        # string (p.ej. ?storage_id=...) debe conservarla después del id.
        def view_url(view)
          path, query = url.split("?", 2)
          "#{path.chomp('/')}/#{view.id}#{"?#{query}" if query}"
        end

        # Payload del estado actual, serializado para el hidden del form de guardar. Las
        # columnas visibles las agrega el Stimulus al enviar (viven en el DOM del selector).
        def payload_json
          filter_form.current_view_payload.to_json
        end
      end
    end
  end
end
