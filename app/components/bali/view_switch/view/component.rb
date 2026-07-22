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

        # @param name [String] Label of the view (visible text, or the native
        #   tooltip + accessible label when the parent is icon_only)
        # @param icon [String] Icon name rendered before the label
        # @param href [String] Path this view links to
        # @param active [Boolean, nil] Explicit active state; when nil (default)
        #   it is autodetected by matching the request path against href
        # rubocop:disable Metrics/ParameterLists
        def initialize(name:, icon:, href:, active: nil, icon_only: false, size: :sm, **options)
          @name = name
          @icon = icon
          @href = href
          @active = active
          @icon_only = icon_only
          @size = size&.to_sym
          @options = options
        end
        # rubocop:enable Metrics/ParameterLists

        private

        attr_reader :name, :icon, :href, :options

        def icon_only?
          @icon_only
        end

        def active?
          return @active unless @active.nil?

          active_path?(request.fullpath, href)
        end

        def link_attributes
          attrs = options.except(:class).merge(
            class: link_classes,
            "aria-pressed": active?.to_s
          )

          if icon_only?
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
            active? ? "btn-active btn-primary" : "btn-outline",
            options[:class]
          )
        end
      end
    end
  end
end
