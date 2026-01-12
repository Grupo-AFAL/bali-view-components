# frozen_string_literal: true

module Bali
  module Drawer
    class Component < ApplicationViewComponent
      SIZES = {
        narrow: 'max-w-sm',
        medium: 'max-w-lg',
        wide: 'max-w-2xl',
        extra_wide: 'max-w-4xl'
      }.freeze

      def initialize(active: false, size: :medium, **options)
        @active = active
        @size = size&.to_sym
        @options = options
      end

      def drawer_classes
        class_names(
          'drawer-component',
          @active && 'drawer-open',
          @options[:class]
        )
      end

      def panel_classes
        class_names(
          'drawer-panel',
          'fixed top-0 right-0 h-full w-full',
          SIZES[@size] || SIZES[:medium],
          'bg-base-100 shadow-2xl',
          'transform translate-x-full transition-transform duration-300 ease-in-out',
          'overflow-auto z-50'
        )
      end
    end
  end
end
