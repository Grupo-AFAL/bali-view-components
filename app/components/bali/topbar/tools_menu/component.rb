# frozen_string_literal: true

module Bali
  module Topbar
    module ToolsMenu
      # El menú de herramientas internas del topbar: panel de trabajos, tableros, bandeja de
      # correo, repositorio, monitoreo. Va en el slot `with_action` de `Bali::Topbar`.
      #
      # Recibe las herramientas YA FILTRADAS POR PERMISO. La gema no evalúa permisos: los
      # hosts que la usan no comparten vocabulario de autorización (unos tienen permisos con
      # nombre, otros policies), y dejar esa decisión afuera es lo que permite que el mismo
      # componente les sirva a todos sin casos especiales.
      #
      # Lo que sí decide el componente es qué existe en ESTE ambiente, preguntándole a su
      # propio contexto de vista (ver `Tool#available?`). Si no queda ninguna, no se
      # renderiza: un trigger que abre un panel vacío es peor que no tenerlo.
      class Component < ApplicationViewComponent
        # @param tools [Array<Tool>] ya filtradas por permiso.
        # @param icon [String] ícono del trigger.
        # @param aria_label [String, nil] nombre accesible del trigger; por default el
        #   traducido. Es de sólo ícono: sin nombre accesible no tiene nombre.
        # @param align [Symbol] eje horizontal del dropdown.
        def initialize(tools:, icon: "wrench", aria_label: nil, align: :end, **options)
          @tools = Array(tools)
          @icon = icon
          @aria_label = aria_label
          @align = align
          @options = options
        end

        def render?
          visible_tools.any?
        end

        # `helpers` es el contexto de vista del render en curso: el colaborador que ya
        # tenemos, en vez de alcanzar `Rails.application`.
        def visible_tools
          @visible_tools ||= @tools.select { |tool| tool.available?(helpers) }
        end

        def href_for(tool)
          tool.href(helpers)
        end

        # `name:` explícito → clave del host → clave de la gema → humanize.
        def label_for(tool)
          return tool.name if tool.name.present?

          t("topbar.tools_menu.items.#{tool.key}",
            default: [ :"bali_view.topbar.tools_menu.items.#{tool.key}", tool.key.to_s.humanize ])
        end

        # Clave del host → clave de la gema. Mismo patrón que `label_for`, para que quien
        # aprenda el override en los ítems lo encuentre también en el trigger.
        def trigger_label
          @aria_label ||
            t("topbar.tools_menu.trigger_label", default: :"bali_view.topbar.tools_menu.trigger_label")
        end

        def link_options(tool)
          return {} unless tool.new_tab?

          { target: "_blank", rel: "noopener" }
        end

        def dropdown_options
          @options.merge(
            align: @align,
            class: class_names("bali-topbar-tools-menu", @options[:class])
          )
        end

        attr_reader :icon
      end
    end
  end
end
