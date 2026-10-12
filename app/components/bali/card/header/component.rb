# frozen_string_literal: true

module Bali
  module Card
    module Header
      class Component < ApplicationViewComponent
        renders_one :badge

        # @param icon_class [String, nil] Extra classes for the icon alone. A class on
        #   the header itself paints the `<h2>` with it too, because the Lucide SVG
        #   inherits `currentColor` from this wrapper — so an amber icon over a neutral
        #   title needs this hook (#1148).
        def initialize(title:, subtitle: nil, icon: nil, icon_class: nil, **options)
          @title = title
          @subtitle = subtitle
          @icon = icon
          @icon_class = icon_class
          @options = options
        end

        def call
          tag.div(class: header_classes, **@options.except(:class)) do
            safe_join([ render_heading, badge ].compact)
          end
        end

        private

        def header_classes
          class_names(
            "flex flex-wrap items-center gap-3",
            @options[:class],
            "justify-between" => badge?
          )
        end

        # The icon and the titles are one flex item: as two, `justify-between` puts
        # the same gap between the icon and the title as between the title and the
        # badge (#1372).
        def render_heading
          tag.div(class: "flex items-center gap-3 min-w-0") do
            safe_join([ render_icon, render_titles ].compact)
          end
        end

        def render_icon
          return unless @icon

          render Bali::Icon::Component.new(@icon, class: class_names("size-6 shrink-0", @icon_class))
        end

        def render_titles
          tag.div do
            safe_join([
              tag.h2(@title, class: "card-title"),
              render_subtitle
            ].compact)
          end
        end

        def render_subtitle
          return unless @subtitle

          tag.p(@subtitle, class: "text-sm text-base-content/70")
        end
      end
    end
  end
end
