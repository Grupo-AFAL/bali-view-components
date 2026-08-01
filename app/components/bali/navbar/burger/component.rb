# frozen_string_literal: true

module Bali
  module Navbar
    module Burger
      class Component < ApplicationViewComponent
        BASE_CLASSES = "btn btn-ghost lg:hidden"
        ICON_CLASSES = "h-5 w-5"

        CONFIGURATIONS = {
          main: { target: "burger", action: "navbar#toggleMenu" },
          alt: { target: "altBurger", action: "navbar#toggleAltMenu" },
          sidebar: {}
        }.freeze

        # @param type [Symbol] :main (navbar menu), :alt, :sidebar (side menu)
        # @param menu_id [String] id of the SideMenu opened by `type: :sidebar`
        # @param href [String] When provided, renders as a simple link instead of a button
        def initialize(type: :main,
                       menu_id: Bali::SideMenu::Component::DEFAULT_ID,
                       href: nil,
                       **options)
          @type = type
          @menu_id = menu_id
          @href = href
          # The sidebar button delegates its styling to SideMenu::Trigger; the
          # link form still renders here, so it keeps the burger's own classes.
          @options = @href || !sidebar? ? prepend_class_name(options, BASE_CLASSES) : options

          configure_attrs unless type.nil? || @href
        end

        # `type: :sidebar` renders Bali::SideMenu::Trigger::Component rather than
        # its own markup. It used to be a `<label for=…>` pointing at a hidden
        # checkbox — a third hamburger markup with a second opening mechanism,
        # and one no keyboard could reach. There is now a single trigger, so the
        # navbar burger gets `aria-expanded`, `aria-controls` and focus
        # restoration for free.
        def call
          if @href
            tag.a(href: @href, 'aria-label': t(".toggle_menu"), **@options) do
              content.presence || default_icon
            end
          elsif sidebar?
            render(sidebar_trigger) { content.presence || default_icon }
          else
            tag.button(type: "button", 'aria-label': t(".toggle_menu"), **@options) do
              content.presence || default_icon
            end
          end
        end

        private

        attr_reader :type, :options

        def sidebar?
          @type == :sidebar
        end

        def sidebar_trigger
          Bali::SideMenu::Trigger::Component.new(
            menu_id: @menu_id,
            icon: nil,
            'aria-label': t(".toggle_menu"),
            class: class_names("lg:hidden", @options[:class]),
            **@options.except(:class)
          )
        end

        def configure_attrs
          attrs = CONFIGURATIONS.fetch(@type, CONFIGURATIONS[:main])

          prepend_action(@options, attrs[:action]) if attrs[:action]
          prepend_data_attribute(@options, "navbar-target", attrs[:target]) if attrs[:target]
        end

        def default_icon
          tag.svg(
            xmlns: "http://www.w3.org/2000/svg",
            class: ICON_CLASSES,
            fill: "none",
            viewBox: "0 0 24 24",
            stroke: "currentColor",
            'aria-hidden': "true"
          ) do
            tag.path(
              'stroke-linecap': "round",
              'stroke-linejoin': "round",
              'stroke-width': "2",
              d: "M4 6h16M4 12h8m-8 6h16"
            )
          end
        end
      end
    end
  end
end
