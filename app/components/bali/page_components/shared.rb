# frozen_string_literal: true

module Bali
  module PageComponents
    module Shared
      extend ActiveSupport::Concern

      include Bali::DataTable::ToolbarHref

      # Claves ABSOLUTAS: este concern lo incluyen CINCO componentes, así que `t('.x')`
      # resolvería a cinco scopes sidecar distintos y ninguno existiría.
      SECONDARY_ACTIONS_LABEL_KEY = "view_components.bali.page_components.secondary_actions.button_label"
      EXPORT_MENU_TITLE_KEY = "view_components.bali.page_components.export.menu_title"

      included do
        renders_many :actions
      end

      # Acciones SECUNDARIAS de la página: viven en el ⋯ al lado de la primaria. Se guardan
      # los ARGUMENTOS y no el contenido ya renderizado porque el ⋯ es un Bali::Dropdown de
      # verdad y sus items tienen que pasar por `with_item` para heredar el rol de menuitem y
      # la selección Link/DeleteLink. Mismo patrón que DashboardPage#with_stat.
      #
      # @param options [Hash] Opciones de Bali::Dropdown#with_item (href:, icon_name:,
      #   method:, tag:, authorized:)
      def with_secondary_action(**options, &block)
        secondary_action_items << [ options, block ]
        nil
      end

      # Exportar el listado. Vive acá y no en la toolbar del DataTable porque exportar es una
      # acción SOBRE la página, no un control de cómo se ve el listado — y así importar o
      # imprimir tienen dónde caer después. Se llama "lo filtrado" porque el link arrastra el
      # recorte activo (ver Bali::DataTable::Export::Component#export_url).
      #
      # @param url [String] URL base del listado (sin `format`)
      # @param formats [Array<Symbol>] Formatos a ofrecer
      # @param params [Hash, nil] Recorte a arrastrar. `nil` lo lee del request; `{}` es el
      #   opt-out explícito.
      def with_export(url:, formats: %i[csv excel pdf], params: nil)
        @export_options = { url: url, formats: formats, params: params }
        nil
      end

      private

      def secondary_action_items
        @secondary_action_items ||= []
      end

      def secondary_actions?
        @export_options.present? || secondary_action_items.any?
      end

      def render_secondary_actions
        return unless secondary_actions?

        render(Bali::Dropdown::Component.new(align: :bottom_end,
                                             data: { controller: "export-links" })) do |dropdown|
          # `ellipsis-vertical` y no `ellipsis`: bajo `sm` este menú y el ⋯ del overflow de la
          # toolbar quedan a un palmo uno del otro, y con el mismo icono son dos botones
          # idénticos que abren cosas distintas.
          dropdown.with_trigger(variant: :ghost, class: "btn-sm btn-square",
                                "aria-label": I18n.t(SECONDARY_ACTIONS_LABEL_KEY)) do
            render Bali::Icon::Component.new("ellipsis-vertical", class: "w-4 h-4")
          end
          export_menu_items.each { |item| dropdown.with_item(**item) }
          secondary_action_items.each { |options, block| dropdown.with_item(**options, &block) }
        end
      end

      # El encabezado de sección es lo que NOMBRA la acción ("Exportar lo filtrado"); debajo
      # van los formatos. Con un item por formato y sin título el menú diría "CSV / Excel /
      # PDF" y nadie sabría de qué.
      def export_menu_items
        return [] unless @export_options

        items = [ { tag: :title, name: I18n.t(EXPORT_MENU_TITLE_KEY) } ]
        export_component.export_items.each do |item|
          # `method: nil` para que Link no emita el `data-method="get"` de Rails-UJS, que bajo
          # Turbo no hace nada. `data-turbo="false"` sí hace falta: un CSV no es una respuesta
          # que Turbo Drive pueda renderizar y la visita se queda a mitad de camino en vez de
          # disparar la descarga.
          items << { href: item[:url], name: item[:label], icon_name: item[:icon], method: nil,
                     data: { turbo: false, export_links_target: "link" } }
        end
        items
      end

      # Los params se resuelven ACÁ y se pasan explícitos: el Export se construye para leerle
      # `export_items` y no se renderiza nunca, y `request_query_params` necesita el contexto
      # de render que solo tiene el componente que sí se está pintando.
      def export_component
        @export_component ||= Bali::DataTable::Export::Component.new(
          formats: @export_options[:formats],
          url: @export_options[:url],
          params: @export_options[:params] || request_query_params
        )
      end

      def breadcrumb_spacer_class
        "mt-1" unless breadcrumbs.empty?
      end

      def render_breadcrumbs
        return if breadcrumbs.empty?

        render(Bali::Breadcrumb::Component.new) do |bc|
          breadcrumbs.each { |crumb| bc.with_item(**crumb) }
        end
      end

      # El ⋯ va DENTRO de la barra de acciones y pegado a la primaria: son el mismo grupo.
      def render_actions_bar
        return unless actions? || secondary_actions?

        helpers.tag.div(class: "flex items-center gap-2 flex-wrap max-sm:w-full") do
          helpers.safe_join([ *actions, render_secondary_actions ].compact)
        end
      end

      # Renders the optional nav slot (second-level navigation, e.g. Bali::Tabs)
      # between the PageHeader and the body with standardized spacing.
      def render_nav
        return unless nav?

        helpers.tag.div(class: "page-nav mt-4") { nav.to_s }
      end
    end
  end
end
