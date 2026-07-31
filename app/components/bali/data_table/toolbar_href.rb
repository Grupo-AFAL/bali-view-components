# frozen_string_literal: true

module Bali
  module DataTable
    # Cómo se ve la URL de un listado cuando se cambia UN control de navegación de la
    # toolbar (agrupar por, view switch) o cuando se exporta lo que se está mirando: se
    # mergea el query string actual y solo cambia ese param, así filtros, búsqueda, orden y
    # la vista guardada aplicada sobreviven al click.
    #
    # Está compartido porque las dos derivaciones separadas ya habían divergido: la `url:`
    # del listado PUEDE traer query string (un host que pasa `request.fullpath` o un path
    # helper con params — Export, SavedViews y Filters ya lo contemplan), y concatenar "?" a
    # secas producía `/movies?scope=x?view=grid`, que Rack parsea como un solo param
    # corrupto y sin `view`: el click no cambiaba de vista y además ensuciaba el scope.
    module ToolbarHref
      # Órdenes de un solo uso: son ACCIONES, no estado de navegación — arrastrarlas vuelve
      # a ejecutar el borrado en cada click posterior (`clear_filters` además BORRA la caché
      # de filtros del usuario en el server: `Rails.cache.delete(cache_key)`). `page` se tira
      # porque cambiar de vista o de agrupación vuelve a la primera página, y porque un
      # export que se lleva `page` exporta UNA página en vez del set.
      #
      # GEMELA EN JS: `export_links_controller.js` tira exactamente esta lista al
      # re-sincronizar los hrefs del ⋯ desde `window.location`. Mover un param acá sin
      # moverlo allá deja las dos mitades del mismo link en desacuerdo.
      TRANSIENT_PARAMS = %w[page clear_filters clear_search].freeze

      # @param url [String] URL base del listado, con o sin query string
      # @param current_params [Hash] query params actuales, preservados en el link
      # @param param [String, Symbol] param que cambia este control
      # @param value [String, nil] valor nuevo; `nil` lo saca de la URL
      def build_toolbar_href(url, current_params, param, value)
        base, base_query = url.to_s.split("?", 2)
        key = param.to_s
        params = Rack::Utils.parse_nested_query(base_query.to_s)
          .merge((current_params || {}).to_h.stringify_keys)
          .except(*TRANSIENT_PARAMS, key)
        params[key] = value unless value.nil?

        query = params.to_query
        query.present? ? "#{base}?#{query}" : base
      end

      # El recorte que el usuario está mirando, o `{}` sin contexto de request (previews,
      # `render_inline`). Vive acá y no como método privado del DataTable porque el export
      # se pinta FUERA del componente —en el ⋯ del PageHeader— y tiene que leer el mismo
      # estado sin que nadie se lo pase.
      def request_query_params
        helpers.request.query_parameters.to_h
      rescue StandardError
        {}
      end
    end
  end
end
