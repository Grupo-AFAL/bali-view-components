# frozen_string_literal: true

module Bali
  module Dropdown
    class Component < ApplicationViewComponent
      ALIGNMENTS = {
        left: "",
        right: "dropdown-end",
        top: "dropdown-top",
        bottom: "dropdown-bottom",
        top_end: "dropdown-top dropdown-end",
        bottom_end: "dropdown-bottom dropdown-end"
      }.freeze

      renders_one :trigger, Trigger::Component
      renders_many :items, ->(method: :get, href: nil, tag: :link, **options) do
        if tag == :button
          ActionItem::Component.new(**options)
        else
          component_klass = method&.to_sym == :delete ? DeleteLink::Component : Link::Component
          options[:role] ||= "menuitem"
          component_klass.new(
            method: method, href: href, plain: true,
            **prepend_class_name(options, "menu-item w-full text-left")
          )
        end
      end

      # @param menu [Boolean] Semántica de menú (`<ul role="menu">` de menuitems). En `false`
      #   el panel es un CONTENEDOR genérico: para contenido que no son menuitems (forms,
      #   checkboxes, otros dropdowns), donde `role="menu"` expone hijos no permitidos y hace
      #   que el lector de pantalla entre en modo menú sobre un formulario.
      def initialize(hoverable: false, close_on_click: true, align: :right, wide: false,
                     menu: true, **options)
        @hoverable = hoverable
        @close_on_click = close_on_click
        @align = align&.to_sym
        @wide = wide
        @menu = menu
        @options = options
      end

      def menu?
        @menu
      end

      def menu_tag_name
        menu? ? :ul : :div
      end

      # Sin semántica de menú tampoco va la clase `.menu` de daisyUI: es la que impone
      # display:grid + padding + hover a los hijos directos, y sin ella el contenido en flujo
      # no necesita variantes `!important` para recuperar su propio layout.
      def menu_attributes
        {
          tabindex: -1,
          class: content_classes,
          role: ("menu" if menu?),
          "aria-label": (t(".menu_label") if menu?),
          data: { dropdown_target: "menu" }
        }.compact
      end

      def content_classes
        class_names(
          "dropdown-content",
          ("menu" if menu?),
          "bg-base-100",
          "text-base-content", # Ensure proper text contrast regardless of parent colors
          "rounded-box",
          "z-50",
          "shadow-lg",
          "p-2",
          @wide ? "w-80" : "w-52"
        )
      end

      def render?
        items? ? items.any?(&:authorized?) : content.present?
      end

      private

      def dropdown_classes
        class_names(
          "dropdown",
          ALIGNMENTS[@align],
          "dropdown-hover" => @hoverable
        )
      end

      def dropdown_attributes
        attrs = @options.merge(class: class_names(dropdown_classes, @options[:class]))
        unless @hoverable
          attrs[:data] = (attrs[:data] || {}).merge(
            controller: [ "dropdown", attrs.dig(:data, :controller) ].compact.join(" "),
            dropdown_close_on_click_value: @close_on_click
          )
        end
        attrs
      end
    end
  end
end
