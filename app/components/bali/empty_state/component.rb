# frozen_string_literal: true

module Bali
  module EmptyState
    # Standard empty state: a centered block with an optional icon in a soft
    # circle, a title, an optional description and an optional CTA (link or
    # button) rendered through the `cta` slot. Use it anywhere a section has
    # nothing to show yet — grids, panels, tabs, kanban columns — so every
    # blank state looks the same. `Bali::Table` renders its built-in empty
    # state through this component, so tables and standalone sections match.
    class Component < ApplicationViewComponent
      CONTAINER_CLASSES = "empty-state-component flex flex-col items-center " \
                          "justify-center gap-4 text-center"

      TITLE_CLASSES = "font-medium text-base-content"
      DESCRIPTION_CLASSES = "mt-1 text-base-content/60"

      SIZES = { sm: "py-4", md: "py-8", lg: "py-12" }.freeze
      ICON_CIRCLE_SIZES = { sm: "size-10", md: "size-12", lg: "size-16" }.freeze
      ICON_PIXEL_SIZES = { sm: 20, md: 24, lg: 32 }.freeze

      DEFAULT_SIZE = :md

      renders_one :cta

      attr_reader :title, :description, :icon

      # Single source of truth for the centered container, shared with
      # Bali::Table so custom `no_records_notification` content sits in the
      # exact same block as this component.
      def self.container_classes(size: DEFAULT_SIZE)
        "#{CONTAINER_CLASSES} #{SIZES.fetch(size, SIZES[DEFAULT_SIZE])}"
      end

      def initialize(title:, description: nil, icon: nil, size: DEFAULT_SIZE, **options)
        @title = title
        @description = description
        @icon = icon
        @size = size&.to_sym
        @options = options
      end

      private

      attr_reader :options

      def size
        SIZES.key?(@size) ? @size : DEFAULT_SIZE
      end

      def container_attributes
        options.except(:class)
               .merge(class: class_names(self.class.container_classes(size: size), options[:class]))
      end

      def icon_circle_classes
        class_names("flex items-center justify-center rounded-full bg-base-200 " \
                    "text-base-content/60", ICON_CIRCLE_SIZES[size])
      end

      def icon_pixel_size
        ICON_PIXEL_SIZES[size]
      end
    end
  end
end
