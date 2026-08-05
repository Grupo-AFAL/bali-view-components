# frozen_string_literal: true

module Bali
  module Dropdown
    class Component < ApplicationViewComponent
      include Bali::DeprecatedIconName

      # daisyUI 5 splits a dropdown's position along two axes and gives each its own class.
      # This component used to fold both into one `align:` keyword that could spell four of
      # the twelve combinations, and Bali::ActionsDropdown kept a second, incompatible pair
      # of tables. One table per axis now, each named after the daisyUI class it emits.
      ALIGNMENTS = {
        start: "dropdown-start",
        center: "dropdown-center",
        end: "dropdown-end"
      }.freeze

      DIRECTIONS = {
        top: "dropdown-top",
        bottom: "dropdown-bottom",
        left: "dropdown-left",
        right: "dropdown-right"
      }.freeze

      # ActionsDropdown's scale, kept whole: `wide:` was a boolean over two of these four.
      WIDTHS = {
        sm: "w-40",
        md: "w-52",
        lg: "w-64",
        xl: "w-80"
      }.freeze

      # The v2 spellings of `align:`, and the v3 sentence each one becomes. They raise rather
      # than resolve, and `:left` / `:right` are why: both are now valid values of the OTHER
      # axis, where they mean a menu opening sideways. Mapping them quietly would have moved
      # the menu rather than failed.
      MOVED_ALIGNMENTS = {
        left: "align: :start",
        right: "align: :end",
        top: "direction: :top",
        bottom: "direction: :bottom",
        top_end: "direction: :top, align: :end",
        bottom_end: "direction: :bottom, align: :end"
      }.freeze

      WIDE_REMOVED_MESSAGE = "Bali::Dropdown::Component no longer accepts `wide:`. " \
                             "`wide: true` is `width: :xl` (w-80) and `wide: false` is the " \
                             "default `width: :md` (w-52)."

      renders_one :trigger, Trigger::Component

      # @param tag [Symbol] `:link` (default), `:button` (acción JS, evita el `href="#"`) o
      #   `:title` (encabezado de sección: agrupa los items que le siguen).
      # @param icon [String, Symbol] icon name — one spelling whichever component the item
      #   turns out to be.
      renders_many :items, ->(method: :get, href: nil, tag: :link, icon: nil,
                              icon_name: nil, **options) do
        icon = item_icon(icon, icon_name)

        case tag
        when :title
          Title::Component.new(**options)
        when :button
          ActionItem::Component.new(icon: icon, **options)
        else
          build_link_item(method: method, href: href, icon: icon, **options)
        end
      end

      # @param align [Symbol] horizontal axis: `:start` (default), `:center`, `:end`.
      # @param direction [Symbol] the side the menu opens towards: `:top`, `:bottom`,
      #   `:left`, `:right`. Left out, daisyUI's own default (below the trigger) applies.
      # @param width [Symbol] `:sm` (w-40), `:md` (w-52, default), `:lg` (w-64), `:xl` (w-80).
      # @param popover [Boolean] portal the menu out of any ancestor whose `overflow` would
      #   clip it — what a dropdown in a scrollable table always needs. The keyboard is the
      #   same in both modes; see `app/components/bali/dropdown/index.js`.
      # @param menu [Boolean] Semántica de menú (`<ul role="menu">` de menuitems). En `false`
      #   el panel es un CONTENEDOR genérico: para contenido que no son menuitems (forms,
      #   checkboxes, otros dropdowns), donde `role="menu"` expone hijos no permitidos y hace
      #   que el lector de pantalla entre en modo menú sobre un formulario.
      # rubocop:disable Metrics/ParameterLists
      def initialize(align: :start, direction: nil, width: :md, popover: false,
                     hoverable: false, close_on_click: true, menu: true, **options)
        # rubocop:enable Metrics/ParameterLists
        reject_wide!(options)

        @align = align&.to_sym
        @direction = direction&.to_sym
        @width = width&.to_sym
        @align_class = lookup!(:align, @align, ALIGNMENTS)
        @direction_class = lookup!(:direction, @direction, DIRECTIONS)
        @width_class = lookup!(:width, @width, WIDTHS)
        @popover = popover
        @hoverable = hoverable
        @close_on_click = close_on_click
        @menu = menu
        @options = options
      end

      def menu?
        @menu
      end

      def popover?
        @popover
      end

      def menu_tag_name
        menu? ? :ul : :div
      end

      # The key is absolute rather than the usual relative `.menu_label`. A relative key
      # resolves against the scope of the class the instance IS, and Bali::ActionsDropdown
      # is now a subclass, so it would look under `bali_view.actions_dropdown` and find
      # nothing — the label of the menu belongs to the menu, not to whichever preset built
      # it, and a host that has already overridden this key keeps overriding both.
      MENU_LABEL_KEY = "bali_view.dropdown.menu_label"

      # Sin semántica de menú tampoco va la clase `.menu` de daisyUI: es la que impone
      # display:grid + padding + hover a los hijos directos, y sin ella el contenido en flujo
      # no necesita variantes `!important` para recuperar su propio layout.
      def menu_attributes
        {
          tabindex: -1,
          class: content_classes,
          role: ("menu" if menu?),
          "aria-label": (t(MENU_LABEL_KEY) if menu?),
          data: { dropdown_target: "menu" }
        }.compact
      end

      # One class list for both modes, `dropdown-content` included. In popover mode the
      # controller strips that one class at the moment it hands the panel to tippy, and not
      # before: until then `.dropdown-content` is what keeps the panel closed, so the panel
      # does not flash open in the window between the server's HTML and a dynamically
      # imported tippy resolving. It is also the whole no-JS fallback — a popover dropdown
      # whose JavaScript never arrives is the plain CSS dropdown, clipped but working.
      def content_classes
        class_names(
          "dropdown-content",
          ("menu" if menu?),
          "bg-base-100",
          "text-base-content", # Ensure proper text contrast regardless of parent colors
          "rounded-box",
          "z-[var(--bali-z-dropdown)]",
          "shadow-lg",
          "p-2",
          @width_class
        )
      end

      # Los encabezados no cuentan: un menú de puros títulos destapa un botón que abre algo
      # sin ninguna opción para elegir.
      def render?
        items? ? items.any? { |item| item.authorized? && !section_title?(item) } : content.present?
      end

      def authorized_items
        @authorized_items ||= items.select(&:authorized?)
      end

      # What the template renders when no `trigger` slot was given. Nothing here — a plain
      # dropdown has no trigger to guess. Bali::ActionsDropdown is the preset that overrides
      # it with its ellipsis button, and that override is the whole of the difference
      # between the two components.
      def default_trigger
        nil
      end

      private

      # `method:` is what picks the component, and DeleteLink has no `method:` keyword of its
      # own — passing it through landed in **options and painted `<button method="delete">`,
      # an attribute that means nothing to a browser. The verb reaches DeleteLink through the
      # `button_to` it builds, not through this hash.
      def build_link_item(method:, href:, icon:, **options)
        options[:role] ||= "menuitem"
        options = prepend_class_name(options, "menu-item w-full text-left")

        if method&.to_sym == :delete
          # `form_class: "contents"` explícito, porque acá SÍ es item de menú: daisyUI pinta
          # el item sobre `li > *` salvo que sea un `.btn`, y el `<form>` de `button_to` no lo
          # es. Fuera del árbol de cajas, el botón es el item (#829). Antes esto lo deducía
          # DeleteLink de `plain:`, que no significa eso (#868). Va ANTES de `**options` para
          # que un call site lo pueda pisar.
          DeleteLink::Component.new(
            href: href, plain: true, icon: icon, form_class: "contents", **options
          )
        else
          Link::Component.new(method: method, href: href, plain: true, icon: icon, **options)
        end
      end

      # `icon:` is the spelling v3 settled on when DeleteLink merged its two icon keywords
      # (#774). `with_item` translated between them as a bridge; now that one lambda builds
      # both kinds of item there is one keyword, and the old one warns on the way out.
      def item_icon(icon, icon_name)
        icon || deprecated_icon_name(icon_name, on: "with_item")
      end

      def section_title?(item)
        item.respond_to?(:menu_title?) && item.menu_title?
      end

      def lookup!(param, value, table)
        return nil if value.nil?
        return table[value] if table.key?(value)

        raise ArgumentError, rejection_message(param, value, table)
      end

      def rejection_message(param, key, table)
        if param == :align && MOVED_ALIGNMENTS.key?(key)
          return "#{self.class}: align: #{key.inspect} is now written " \
                 "`#{MOVED_ALIGNMENTS[key]}`. The two axes daisyUI keeps apart have a " \
                 "keyword each: align: is the horizontal one, direction: the side."
        end

        "#{self.class}: unknown #{param} #{key.inspect}. " \
          "Valid: #{table.keys.map(&:inspect).join(', ')}."
      end

      def reject_wide!(options)
        return unless options.key?(:wide)

        raise ArgumentError, WIDE_REMOVED_MESSAGE
      end

      def dropdown_classes
        class_names(
          "dropdown",
          @align_class,
          @direction_class,
          "dropdown-hover" => @hoverable
        )
      end

      # The controller is attached in every mode now, `hoverable:` included. daisyUI opens a
      # hover dropdown from CSS alone and Bali added nothing to it, so its trigger reported
      # `aria-expanded="false"` with the menu on screen — the WCAG 4.1.2 hole that was closed
      # for the click dropdown and left open in the one beside it. The CSS still does the
      # opening; what the controller adds is the attribute, the arrow keys and the Escape.
      def dropdown_attributes
        attrs = @options.merge(class: class_names(dropdown_classes, @options[:class]))
        attrs[:data] = (attrs[:data] || {}).merge(
          controller: [ "dropdown", attrs.dig(:data, :controller) ].compact.join(" "),
          dropdown_close_on_click_value: @close_on_click,
          dropdown_popover_value: @popover,
          dropdown_placement_value: tippy_placement
        )
        attrs
      end

      # tippy's vocabulary for the same two axes, read in popover mode only. daisyUI's
      # `dropdown-left` / `dropdown-right` put the menu beside the trigger rather than under
      # it, which tippy spells `left-start` / `right-start`; `center` is tippy's unsuffixed
      # placement, so it contributes nothing.
      TIPPY_ALIGNMENTS = { start: "-start", center: "", end: "-end" }.freeze
      private_constant :TIPPY_ALIGNMENTS

      TIPPY_SIDES = { top: "top", left: "left", right: "right", bottom: "bottom" }.freeze
      private_constant :TIPPY_SIDES

      def tippy_placement
        "#{TIPPY_SIDES.fetch(@direction, 'bottom')}#{TIPPY_ALIGNMENTS.fetch(@align, '-start')}"
      end
    end
  end
end
