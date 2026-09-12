# frozen_string_literal: true

module Bali
  module ViewSwitch
    module View
      class Component < ApplicationViewComponent
        SIZES = {
          xs: "btn-xs",
          sm: "btn-sm",
          md: "",
          lg: "btn-lg",
          xl: "btn-xl"
        }.freeze

        # `aria-current` value per parent mode: the active view of a navigation
        # switch IS the current page; the active view of a selector is only the
        # current item of its set.
        ARIA_CURRENT = {
          navigation: "page",
          selector: "true"
        }.freeze

        # @param name [String] Label of the view (visible text, or the native
        #   tooltip + accessible label when the parent is icon_only)
        # @param icon [String, nil] Icon name rendered before the label; nil renders
        #   a text-only view (the norm in `mode: :selector`, where the options are
        #   values — "12 months", "Optimistic" — not views with an iconography)
        # @param href [String] Path this view links to
        # @param active [Boolean, nil] Explicit active state; when nil (default)
        #   it is autodetected by matching the request path against href
        # rubocop:disable Metrics/ParameterLists
        def initialize(name:, icon: nil, href:, active: nil, icon_only: false, size: :sm,
                       mode: :navigation, **options)
          @name = name
          @icon = icon
          @href = href
          @active = active
          @icon_only = icon_only
          @size = size&.to_sym
          @mode = mode&.to_sym
          @options = options
        end
        # rubocop:enable Metrics/ParameterLists

        private

        attr_reader :name, :icon, :href, :options

        def icon_only?
          @icon_only == true
        end

        # `:responsive` colapsa el texto por CSS bajo sm, pero emite title/aria-label SIEMPRE:
        # esconder el label con `max-sm:hidden` a secas dejaría un botón sin nombre accesible
        # justo en el viewport donde solo se ve el icono.
        def responsive_icon_only?
          @icon_only == :responsive
        end

        def active?
          return @active unless @active.nil?

          active_path?(request.fullpath, href)
        end

        # `aria-current` y no `aria-pressed`: esto es un `<a>` que NAVEGA (role=link) y
        # el navegador descarta `pressed` sobre un link — el modo activo quedaba expresado
        # solo por color y los tres links sonaban idénticos ("Tabla, link / Tarjetas, link").
        # `aria-current` es un atributo global, permitido en cualquier rol. Vale también
        # para `mode: :selector` (sigue siendo un link que navega): cambia el VALOR
        # (`"true"`, el ítem actual de un set) porque la opción activa de un selector
        # de recorte no es "la página actual".
        def link_attributes
          attrs = options.except(:class).merge(class: link_classes)
          attrs[:"aria-current"] = ARIA_CURRENT.fetch(@mode, "page") if active?

          if icon_only? || responsive_icon_only?
            attrs[:title] ||= name
            attrs[:"aria-label"] ||= name
          end

          attrs
        end

        def link_classes
          class_names(
            "btn",
            "join-item",
            SIZES.fetch(@size, ""),
            icon_only? ? "btn-square" : "gap-1.5",
            ("max-sm:btn-square" if responsive_icon_only?),
            active? ? "btn-active btn-primary" : "btn-outline",
            options[:class]
          )
        end
      end
    end
  end
end
