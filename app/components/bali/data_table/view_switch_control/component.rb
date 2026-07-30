# frozen_string_literal: true

module Bali
  module DataTable
    module ViewSwitchControl
      # Segmented control de vistas del DataTable. Envuelve a Bali::ViewSwitch y le agrega
      # lo único que el switch genérico no puede saber: cómo se ve la URL de ESTE listado.
      #
      # Cada vista declara `value:` (lo que viaja en `?view=`) y el href lo arma este
      # componente mergeando el query string actual — mismo criterio que
      # GroupByControl#build_href: se tira `page` (cambiar de vista vuelve a la primera) y
      # sobreviven filtros, búsqueda, orden y agrupación.
      #
      # `saved_view` SÍ viaja acá, al revés que en Bali::Filters (EXCLUDED_PARAMS). Allá es
      # un SUBMIT de filtros: reenviarlo hacía que el server re-aplicara el payload de la
      # vista encima de lo que el usuario acababa de escribir (#669). Acá es NAVEGACIÓN:
      # cambiar de modo de visualización sin salirse de la vista guardada es exactamente lo
      # que se espera.
      #
      # El nombre es ViewSwitchControl y no ViewSwitch (convención de GroupByControl): dentro
      # de `module Bali::DataTable` la constante `ViewSwitch::Component` sombrearía a
      # `Bali::ViewSwitch::Component`.
      class Component < ApplicationViewComponent
        View = Struct.new(:name, :icon, :value, :href, :active, :options, keyword_init: true)

        MISSING_TARGET_MESSAGE = "with_view necesita `value:` (una vista de esta misma ruta) " \
          "o `href:` (una vista que vive en otra ruta)."

        # @param url [String] URL base del listado (la misma `url:` del DataTable)
        # @param current_params [Hash] query params actuales, preservados en cada link
        # @param param [String, Symbol] param que lleva la vista (default "view")
        # @param current [Symbol, String, nil] vista pedida, CRUDA: se valida contra las
        #   vistas declaradas (ver #current_value)
        # @param aria_label [String] label accesible del grupo (default i18n)
        # @param options [Hash] pasan tal cual a Bali::ViewSwitch (size:, icon_only:, class:)
        def initialize(url:, current_params: {}, param: :view, current: nil, aria_label: nil, **options)
          @url = url.to_s
          @current_params = (current_params || {}).to_h.with_indifferent_access
          @param = param.to_s
          @current = current
          @aria_label = aria_label
          @options = options
          @views = []
        end

        attr_reader :views, :param, :options

        # DSL del slot: dt.with_view_switch { |vs| vs.with_view(name:, icon:, value:) }
        def with_view(name:, icon:, value: nil, href: nil, active: nil, **view_options)
          raise ArgumentError, MISSING_TARGET_MESSAGE if value.nil? && href.nil?

          @views << View.new(name: name, icon: icon, value: value&.to_sym,
                             href: href, active: active, options: view_options)
          self
        end

        def render?
          views.any?
        end

        def aria_label
          @aria_label || t(".aria_label")
        end

        # Valores de las vistas que viven en ESTA ruta (las que traen `value:`).
        def declared_values
          @declared_values ||= views.filter_map(&:value)
        end

        # El `?view=` crudo nunca llega al contenido sin pasar por la lista de vistas
        # declaradas: un valor desconocido cae a la primera en vez de dejar el listado
        # vacío. Misma frontera que FilterForm#resolve_group_by.
        def current_value
          return @current&.to_sym if declared_values.empty?

          declared_values.include?(@current&.to_sym) ? @current.to_sym : declared_values.first
        end

        def view_attributes(view)
          {
            name: view.name,
            icon: view.icon,
            href: view.href || href_for(view.value),
            active: resolve_active(view),
            **view.options
          }
        end

        private

        # Una vista con `href:` propio (otra ruta) no se marca acá: la autodetección por
        # path de Bali::ViewSwitch es la que sabe si estamos parados encima.
        def resolve_active(view)
          return view.active unless view.active.nil?
          return nil if view.value.nil?

          view.value == current_value
        end

        # Mismo criterio que GroupByControl#build_href: `page` se tira (cambiar de vista
        # vuelve a la primera) y las órdenes de un solo uso (clear_filters/clear_search) no
        # viajan — son acciones, no estado de navegación.
        def href_for(value)
          params = @current_params.except("page", "clear_filters", "clear_search", param)
          params = params.merge(param => value.to_s)
          query = params.to_query
          query.present? ? "#{@url}?#{query}" : @url
        end
      end
    end
  end
end
