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
        include Bali::DataTable::ListingIdentity

        DefaultView = Struct.new(:name, :url, keyword_init: true)

        # @param filter_form [Bali::FilterForm] con saved_views_store configurado
        # @param url [String] base RESTful de la app para crear/renombrar/borrar vistas
        # @param base_url [String] URL del listado donde se aplican (?saved_view=<id>)
        # @param listing_id [String] identidad del listado (para capturar las columnas
        #   visibles del selector al guardar; ver Bali::DataTable::ListingIdentity)
        # @param default_views [Array<Hash>] atajos estáticos {name:, url:}
        def initialize(filter_form:, url:, base_url:, listing_id: nil, default_views: nil)
          @filter_form = filter_form
          @url = url
          @base_url = base_url.to_s
          @listing_id = listing_id.to_s.delete_prefix("#")
          @default_views = Array(default_views).map { |view| DefaultView.new(**view.to_h.symbolize_keys) }
        end

        attr_reader :filter_form, :url, :listing_id, :default_views

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

        # La vista ACTIVA que se señala en el dropdown y da nombre al botón. Prioridad:
        # la aplicada por URL (?saved_view=), luego la personal cuyo payload coincide con el
        # estado actual del form (sobrevive a la persistencia, que reescribe la URL limpia),
        # y al final el atajo estático cuya query coincide. Una sola gana: sin doble marca.
        def active_view
          return @active_view if defined?(@active_view)

          @active_view = current_view ||
                         views.find { |view| filter_form.view_matches_current_state?(view) } ||
                         default_views.find { |view| default_view_active?(view) }
        end

        # El botón nombra la vista ACTIVA; sin ninguna aplicada, el label genérico.
        def button_label
          active_view ? active_view.name : t(".button_label")
        end

        def active_view?(view)
          view.equal?(active_view) ||
            (!view.is_a?(DefaultView) && !active_view.is_a?(DefaultView) &&
             active_view&.id == view.id)
        end

        # Marca del item activo. NO `menu-active`: en daisyUI 5 esa clase pinta el item con
        # `neutral`, o sea un bloque negro sólido que se come el resto del menú. El estándar
        # de este repo para "esto es lo seleccionado" dentro de una lista es texto primary sin
        # fondo — igual que SlimSelect (`.ss-selected`, slim_select.css:607) y que el dropdown
        # hermano de "Agrupar por" (GroupByControl#item_class).
        def active_item_class(view)
          "text-primary font-medium" if active_view?(view)
        end

        # La vista sobre la que se está trabajando, aunque ya se le hayan cambiado filtros
        # (sobrevive al submit vía `view_origin`). Es la que se ofrece ACTUALIZAR.
        def origin_view = filter_form.saved_view_origin

        # Solo se ofrece actualizar si hay de dónde venir Y el estado cambió: con el estado
        # intacto el botón prometería guardar algo que ya está guardado.
        def updatable? = filter_form.saved_view_dirty?

        def update_label = t(".update_current", name: origin_view.name)

        def update_confirm = t(".update_confirm", name: origin_view.name)

        # Con una vista modificada, guardar de nuevo es "guardar como NUEVA": el texto lo dice
        # para que no se confunda con actualizar la que ya existe.
        def save_label = updatable? ? t(".save_as_new") : t(".save_current")

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

        # Columnas que IMPUSO la vista aplicada. El selector solo se pinta en modo tabla, y
        # sin él el JS caía a localStorage — que es la memoria del dispositivo ANTERIOR a la
        # vista: guardar una vista nueva desde tarjetas la persistía con columnas que el
        # usuario no estaba viendo.
        def server_columns_json
          Array(filter_form.try(:saved_view_columns)).map(&:to_i).to_json
        end

        private

        # Un atajo estático está activo cuando la query de su URL describe el MISMO estado
        # que el form tiene aplicado. Su query se traduce a la forma del payload: q[g]→
        # groupings, q[m]→combinator, el predicado de búsqueda→search_value (el form lo lleva
        # ahí, no en attributes), `group_by` (param top-level, fuera de q) y el resto de q→
        # attributes. Traducir de menos daba tanto falsos positivos (un atajo que solo agrupa
        # normalizaba a vacío) como falsos negativos (un atajo con búsqueda nunca casaba).
        def default_view_active?(view)
          uri = URI.parse(view.url.to_s)
          params = uri.query.present? ? Rack::Utils.parse_nested_query(uri.query) : {}
          q = params.fetch("q", {})
          q = {} unless q.is_a?(Hash)
          filter_form.state_matches_current_state?(
            "attributes" => q.except("g", "m", *search_predicate),
            "groupings" => q["g"],
            "combinator" => q["m"],
            "search_value" => search_predicate && q[search_predicate],
            "group_by" => params["group_by"]
          )
        rescue URI::InvalidURIError
          false
        end

        # Predicado combinado que emite el buscador rápido (p.ej. "name_or_code_cont"), o nil
        # si este listado no tiene búsqueda.
        def search_predicate
          return @search_predicate if defined?(@search_predicate)

          fields = filter_form.try(:search_config)&.dig(:fields)
          @search_predicate = fields.presence && "#{Array(fields).map(&:to_s).join('_or_')}_cont"
        end
      end
    end
  end
end
