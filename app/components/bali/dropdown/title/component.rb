# frozen_string_literal: true

module Bali
  module Dropdown
    module Title
      # Encabezado de sección de un menú: es lo que deja AGRUPAR items bajo un nombre sin
      # abrir un submenú. El column selector y las vistas guardadas ya pintaban un
      # `menu-title` a mano; esto es el primitivo que les faltaba.
      #
      # Span y no `<li>`: el template del Dropdown ya envuelve cada item en `<li role="none">`.
      class Component < ApplicationViewComponent
        # `role="presentation"`: dentro de un `<ul role="menu">` un span genérico es un hijo
        # que ese rol no admite (solo menuitem/group/separator), y el lector de pantalla en
        # modo menú lo saltea igual. Marcado como presentacional deja de ser un hijo inválido,
        # y el texto sigue disponible para el `aria-describedby` con el que los items de la
        # sección se lo apropian (ver PageComponents::Shared#export_menu_items).
        def initialize(name: nil, **options)
          @name = name
          @options = prepend_class_name(options, "menu-title").reverse_merge(role: "presentation")
        end

        # El Dropdown filtra sus items por este predicado antes de pintarlos (ver
        # Dropdown::Component#render? y su template): un encabezado no tiene permisos.
        def authorized?
          true
        end

        # Un menú de puros encabezados no es un menú — el que decide si el Dropdown pinta es
        # `render?`, y sin esta marca un título solo alcanzaba para destapar un menú vacío.
        def menu_title?
          true
        end

        def call
          tag.span(@name || content, **@options)
        end
      end
    end
  end
end
