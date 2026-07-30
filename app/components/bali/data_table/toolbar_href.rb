# frozen_string_literal: true

module Bali
  module DataTable
    # Cómo se ve la URL de un listado cuando se cambia UN control de navegación de la
    # toolbar (agrupar por, view switch): se mergea el query string actual y solo cambia ese
    # param, así filtros, búsqueda, orden y la vista guardada aplicada sobreviven al click.
    #
    # Está compartido porque las dos derivaciones separadas ya habían divergido: la `url:`
    # del listado PUEDE traer query string (un host que pasa `request.fullpath` o un path
    # helper con params — Export, SavedViews y Filters ya lo contemplan), y concatenar "?" a
    # secas producía `/movies?scope=x?view=grid`, que Rack parsea como un solo param
    # corrupto y sin `view`: el click no cambiaba de vista y además ensuciaba el scope.
    module ToolbarHref
      # Órdenes de un solo uso: son ACCIONES, no estado de navegación — arrastrarlas vuelve
      # a ejecutar el borrado en cada click posterior. `page` se tira porque cambiar de
      # vista o de agrupación vuelve a la primera página.
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
    end
  end
end
