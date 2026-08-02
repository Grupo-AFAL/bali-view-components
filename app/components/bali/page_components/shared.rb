# frozen_string_literal: true

module Bali
  module PageComponents
    module Shared
      extend ActiveSupport::Concern

      include Bali::DataTable::ToolbarHref

      # Claves ABSOLUTAS: este concern lo incluyen CINCO componentes, así que `t('.x')`
      # resolvería a cinco scopes sidecar distintos y ninguno existiría.
      SECONDARY_ACTIONS_LABEL_KEY = "bali_view.page_components.secondary_actions.button_label"
      EXPORT_MENU_TITLE_KEY = "bali_view.page_components.export.menu_title"

      # UNA tabla de anchos para los cinco. Antes vivía duplicada en DashboardPage (cuatro
      # claves, sin `sm`/`md`) y en FormPage (cinco, sin `2xl`), y los otros tres no tenían
      # `max_width:` en absoluto — así que el mismo símbolo significaba un ancho distinto
      # según el componente, o nada.
      MAX_WIDTHS = {
        sm: "max-w-xl",
        md: "max-w-3xl",
        lg: "max-w-5xl",
        xl: "max-w-7xl",
        "2xl": "max-w-screen-2xl",
        full: "max-w-full"
      }.freeze

      # El grid de cuerpo + barra lateral, parametrizado. `:default` es el 2/3 + 1/3 que
      # ShowPage y FormPage tenían copiado literal.
      SIDEBAR_WIDTHS = {
        narrow: { grid: "lg:grid-cols-4", main: "lg:col-span-3" },
        default: { grid: "lg:grid-cols-3", main: "lg:col-span-2" },
        wide: { grid: "lg:grid-cols-2", main: "lg:col-span-1" }
      }.freeze

      # Las keyword args que este concern se queda. Un componente que además recibe opciones
      # sueltas de HTML (DocumentPage) las reparte con `slice`/`except` sobre esta lista en
      # vez de repetir la firma.
      PAGE_OPTIONS = %i[title subtitle breadcrumbs back max_width sidebar_width context].freeze

      # Where the page is being rendered. `:auto` asks the request; the other two state it,
      # which is what lets a test or a Lookbook preview pin the variant without simulating a
      # drawer fetch, and what keeps the component a function of its arguments when the host
      # wants it to be.
      CONTEXTS = %i[auto page drawer].freeze

      # Un solo hueco entre el encabezado (o el nav) y el cuerpo. Antes eran `mt-4` en
      # IndexPage, `mt-6` en ShowPage/FormPage/DocumentPage y ninguno en DashboardPage.
      BODY_SPACING_CLASS = "mt-6"

      included do
        renders_many :actions
        renders_many :title_tags
        renders_one :nav
        renders_one :body
        renders_one :sidebar

        # El ancho por defecto es lo ÚNICO que cambia entre los cinco: la tabla que lo
        # resuelve es la misma. `full` para los que nunca tuvieron contenedor, para que
        # heredarlo no les cambie el layout.
        class_attribute :default_max_width, instance_writer: false, default: :full
      end

      # Firma compartida de los cinco. Un componente que agrega argumentos propios los
      # declara y llama a `super` con el resto.
      def initialize(title:, subtitle: nil, breadcrumbs: [], back: nil, max_width: nil,
                     sidebar_width: :default, context: :auto)
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs.map(&:symbolize_keys)
        @back = back
        @context = resolve_context(context)
        @max_width_key = (max_width || default_max_width).to_sym
        @max_width = MAX_WIDTHS.fetch(@max_width_key) do
          raise ArgumentError,
                "Unknown max_width: #{@max_width_key.inspect}. Valid: #{MAX_WIDTHS.keys.join(', ')}"
        end
        @sidebar_width = resolve_sidebar_width(sidebar_width)
      end

      # Whether this page is rendering as the contents of a Modal or a Drawer. Public, and
      # yielded with the component, because the host's own markup inside the body sometimes
      # has to follow: a Cancel that closes an overlay is not a Cancel that navigates away,
      # and no amount of page chrome can decide that for it.
      #
      # Memoised rather than computed in the constructor: `helpers` needs a view context,
      # which a component only has from `render` onwards.
      def drawer?
        return @drawer if defined?(@drawer)

        @drawer = context == :auto ? drawer_request? : context == :drawer
      end

      # Acciones SECUNDARIAS de la página: viven en el ⋯ al lado de la primaria. Se guardan
      # los ARGUMENTOS y no el contenido ya renderizado porque el ⋯ es un Bali::Dropdown de
      # verdad y sus items tienen que pasar por `with_item` para heredar el rol de menuitem y
      # la selección Link/DeleteLink. Mismo patrón que DashboardPage#with_stat.
      #
      # @param options [Hash] Opciones de Bali::Dropdown#with_item (href:, icon:,
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

      attr_reader :title, :subtitle, :breadcrumbs, :max_width, :context

      # Breadcrumbs and the back button are the two ways OUT of a page, and a drawer is not a
      # page you leave — you close it. Both are therefore chrome the context owns, not values
      # the caller can rescue by passing them: the whole point is that ONE call site works in
      # both places, and the canonical call site passes `back:`. The escape hatch for a drawer
      # that genuinely wants page chrome is `context: :page`, which restores all of it.
      def back
        @back unless drawer?
      end

      def render_breadcrumbs?
        breadcrumbs.any? && !drawer?
      end

      # The component never reads `params`: it asks the host, through
      # `Bali::LayoutConcern#drawer_request?`. That indirection is the point — an app that
      # already declares a `drawer_request?` helper of its own, which is the very pattern this
      # replaces, is detected without touching a line of its controllers, and a view context
      # that declares no such helper (a Lookbook preview, a unit test) renders as a page.
      def drawer_request?
        helpers.respond_to?(:drawer_request?) && helpers.drawer_request?
      end

      def resolve_context(value)
        key = (value || :auto).to_sym
        return key if CONTEXTS.include?(key)

        raise ArgumentError,
              "Unknown context: #{value.inspect}. Valid: #{CONTEXTS.join(', ')}"
      end

      def secondary_action_items
        @secondary_action_items ||= []
      end

      def secondary_actions?
        @export_options.present? || secondary_action_items.any?
      end

      def render_secondary_actions
        return unless secondary_actions?

        render(Bali::Dropdown::Component.new(
          direction: :bottom,
          align: :end,
          data: { controller: "export-links", export_links_sync_value: export_links_sync? }
        )) do |dropdown|
          # `ellipsis-vertical` y no `ellipsis`: bajo `sm` este menú y el ⋯ del overflow de la
          # toolbar quedan a un palmo uno del otro, y con el mismo icono son dos botones
          # idénticos que abren cosas distintas.
          #
          # Sin `btn-sm`: el ⋯ es hermano de flex de la acción primaria y comparte su fila, y
          # el tamaño chico lo dejaba 8px más bajo que el botón al que está pegado. El `sm` es
          # el tamaño de los controles de la TOOLBAR, de donde este menú vino.
          dropdown.with_trigger(variant: :ghost, class: "btn-square",
                                "aria-label": I18n.t(SECONDARY_ACTIONS_LABEL_KEY)) do
            render Bali::Icon::Component.new("ellipsis-vertical", class: "w-5 h-5")
          end
          export_menu_items.each { |item| dropdown.with_item(**item) }
          secondary_action_items.each { |options, block| dropdown.with_item(**options, &block) }
        end
      end

      # El encabezado de sección es lo que NOMBRA la acción ("Exportar lo filtrado"); debajo
      # van los formatos. Con un item por formato y sin título el menú diría "CSV / Excel /
      # PDF" y nadie sabría de qué.
      #
      # El título va además como `aria-describedby` de cada formato: dentro de un
      # `<ul role="menu">` el lector de pantalla navega SOLO los menuitem —igual que
      # `DropdownController#getMenuItems`, que los busca por `[role="menuitem"]`—, así que el
      # texto suelto se saltea y el arreglo quedaba siendo puramente visual. Como descripción
      # y no como `aria-label` para no pisar el nombre accesible: el visible sigue siendo
      # "CSV" y no se rompe "Label in Name".
      def export_menu_items
        return [] unless @export_options

        items = [ { tag: :title, name: I18n.t(EXPORT_MENU_TITLE_KEY), id: export_menu_title_id } ]
        export_component.export_items.each do |item|
          # `method: nil` para que Link no emita el `data-method="get"` de Rails-UJS, que bajo
          # Turbo no hace nada. `data-turbo="false"` sí hace falta: un CSV no es una respuesta
          # que Turbo Drive pueda renderizar y la visita se queda a mitad de camino en vez de
          # disparar la descarga.
          items << { href: item[:url], name: item[:label], icon: item[:icon], method: nil,
                     "aria-describedby": export_menu_title_id,
                     data: { turbo: false, export_links_target: "link" } }
        end
        items
      end

      # Único por render y no fijo: dos page components en la misma página repetirían el id y
      # `aria-describedby` resolvería los dos al primero.
      def export_menu_title_id
        @export_menu_title_id ||= "bali-export-menu-title-#{SecureRandom.hex(4)}"
      end

      # Re-sincronizar los href desde `window.location` es una adivinanza razonable SOLO
      # cuando el recorte salió del request. Con `params:` explícito el host ya decidió qué
      # exportar —incluido `{}`, el opt-out de "exportar todo a propósito"—, y el controlador
      # se lo deshacía apenas booteaba Stimulus, con los tests de Ruby en verde.
      def export_links_sync?
        @export_options.nil? || @export_options[:params].nil?
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
        "mt-1" if render_breadcrumbs?
      end

      def render_breadcrumbs
        return unless render_breadcrumbs?

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

      # El contenedor de la página. `mx-auto` sin `max-w-*` no centra nada, así que van
      # juntos y siempre: `max_width: :full` es un no-op deliberado, no una ausencia.
      def page_container_class(*extra)
        class_names(*extra, "mx-auto", max_width)
      end

      # El encabezado de los cinco. `title:` y `subtitle:` viajan como argumentos del
      # constructor —y no por los slots `with_title`/`with_subtitle`— para que los cinco
      # compartan `PageHeader::TITLE_CLASSES` y `SUBTITLE_CLASSES`, y para que el `h1` lo
      # emita PageHeader: pasarlo por bloque hacía que el slot envolviera el bloque en un
      # heading y el título quedara siendo lo que el bloque decidiera.
      #
      # `title_tags` va al slot homónimo de PageHeader, que los pone como HERMANOS del
      # heading. Dentro del `h1` pasaban a formar parte de su nombre accesible y el
      # encabezado se anunciaba "The Matrix Action Released" (#685).
      def render_page_header
        render(Bali::PageHeader::Component.new(
          title: title,
          subtitle: subtitle,
          back: back,
          class: breadcrumb_spacer_class
        )) do |header|
          title_tags.each { |title_tag| header.with_title_tag { title_tag.to_s } }
          page_header_actions
        end
      end

      # El hueco derecho del encabezado. DocumentPage lo amplía con sus toggles de panel;
      # el resto se queda con la barra de acciones.
      def page_header_actions
        render_actions_bar
      end

      def render_body
        return unless page_body?

        helpers.tag.div(render_body_with_sidebar, class: BODY_SPACING_CLASS)
      end

      # ShowPage y FormPage pintaban el MISMO grid con las mismas seis clases; la única
      # diferencia real era que FormPage envuelve el cuerpo en una Card. Eso es `page_body`,
      # que FormPage redefine, no una copia del grid.
      def render_body_with_sidebar
        return page_body unless sidebar?

        widths = SIDEBAR_WIDTHS.fetch(sidebar_width)

        helpers.tag.div(class: "grid grid-cols-1 #{widths[:grid]} gap-4 lg:gap-6") do
          helpers.safe_join([
            helpers.tag.div(page_body, class: widths[:main]),
            helpers.tag.div(sidebar, class: "space-y-6")
          ])
        end
      end

      # `.to_s` y no el slot pelado: un slot devuelto desde un bloque Ruby llega a `capture`
      # como objeto, y `capture` solo entiende String o SafeBuffer — lo demás lo descarta en
      # silencio y el bloque queda vacío. Mismo motivo que el `nav.to_s` de `render_nav`.
      def page_body
        body.to_s
      end

      def page_body?
        body?
      end

      attr_reader :sidebar_width

      def resolve_sidebar_width(value)
        key = (value || :default).to_sym
        return key if SIDEBAR_WIDTHS.key?(key)

        raise ArgumentError,
              "Unknown sidebar_width: #{value.inspect}. Valid: #{SIDEBAR_WIDTHS.keys.join(', ')}"
      end
    end
  end
end
