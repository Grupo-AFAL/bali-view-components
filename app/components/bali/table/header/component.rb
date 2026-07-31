# frozen_string_literal: true

module Bali
  module Table
    module Header
      class Component < ApplicationViewComponent
        attr_reader :hidden

        SORT_ICONS = { "asc" => "chevron-up", "desc" => "chevron-down" }.freeze
        UNSORTED_ICON = "chevrons-up-down"
        ARIA_SORT = { "asc" => "ascending", "desc" => "descending" }.freeze

        def initialize(name: nil, form: nil, sort: nil, hidden: false, **options)
          @name = name
          @form = form
          @sort_attribute = sort
          @hidden = hidden
          @options = prepend_class_name(hyphenize_keys(options), "whitespace-nowrap")
        end

        def call
          if @sort_attribute.present? && @form.blank?
            raise MissingFilterForm, "FilterForm is required for sorting"
          end

          if sortable?
            opened = helpers.params.delete("opened")
            @name = sort_link
            helpers.params["opened"] = opened
          end

          tag.th(@name, **th_options)
        end

        private

        def sortable?
          @sort_attribute.present? && @form.present?
        end

        # Ransack solo pinta flecha en la columna ORDENADA (`default_arrow` es nil), así que
        # una columna ordenable se veía idéntica a una que no lo es: no había forma de saber
        # que se podía clickear salvo clickeándola. Se apaga su indicador y el label lo arma
        # el componente. OJO: `sort_link` mergea al HREF toda opción que no sea class/data —
        # un `title:` acá termina como `&title=...` en la URL.
        def sort_link
          helpers.sort_link(
            @form.ransack_search, @sort_attribute, sort_link_label,
            hide_indicator: true,
            class: "group inline-flex items-center gap-1"
          )
        end

        def sort_link_label
          safe_join([ @name, sort_indicator ].compact)
        end

        # `aria-hidden` porque el estado ya lo anuncia `aria-sort` en el th; la flecha de
        # texto de Ransack (&#9660;) se leía además como "triángulo negro apuntando abajo".
        def sort_indicator
          render Bali::Icon::Component.new(
            SORT_ICONS.fetch(sort_direction, UNSORTED_ICON),
            class: indicator_classes, "aria-hidden": true
          )
        end

        # Atenuado hasta que el puntero (o el foco de teclado) entra: la afordancia tiene que
        # distinguir la columna ordenable sin competir con el dato de la tabla.
        #
        # Color explícito y NO `opacity`: daisyUI ya pinta el thead con `base-content` al 60%,
        # así que una opacidad se MULTIPLICA contra eso — `opacity-30` medía 1.5:1 contra
        # base-100, debajo del 3:1 que pide WCAG 1.4.11 para un elemento de interfaz. Y como
        # el único realce es hover/focus, en un teléfono no hay forma de subirlo: la afordancia
        # se quedaba ahí para siempre, justo para quien menos la ve.
        def indicator_classes
          return "shrink-0 opacity-100" if sort_direction

          "shrink-0 text-base-content/60 transition-colors " \
            "group-hover:text-base-content group-focus-visible:text-base-content"
        end

        def sort_direction
          return @sort_direction if defined?(@sort_direction)

          @sort_direction = @form.ransack_search.sorts
                                 .find { |sort| sort && sort.name == @sort_attribute.to_s }&.dir
        end

        # `aria-sort` es lo único que le dice a un lector de pantalla que la columna es
        # ordenable y en qué sentido está: la afordancia nueva es puramente visual.
        def th_options
          return @options unless sortable?

          @options.merge("aria-sort": ARIA_SORT.fetch(sort_direction, "none"))
        end
      end
    end
  end
end
