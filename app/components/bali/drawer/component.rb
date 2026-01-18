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

      # Tailwind safelist: group-[.drawer-open]:translate-x-0 max-md:group-[.drawer-open]:max-w-[85%]
      POSITIONS = {
        left: { side: 'left-0', transform: '-translate-x-full', open_class: 'group-[.drawer-open]:translate-x-0' },
        right: { side: 'right-0', transform: 'translate-x-full', open_class: 'group-[.drawer-open]:translate-x-0' }
      }.freeze

      renders_one :header
      renders_one :footer

      attr_reader :drawer_id

      def initialize(
        active: false,
        size: :medium,
        position: :right,
        drawer_id: nil,
        title: nil,
        **options
      )
        @active = active
        @size = size&.to_sym
        @position = position&.to_sym
        @drawer_id = drawer_id || "drawer-#{SecureRandom.hex(4)}"
        @title = title
        @options = options
      end

      def drawer_classes
        class_names(
          'drawer-component group',
          @active && 'drawer-open',
          @options[:class]
        )
      end

      def panel_classes
        position_config = position_settings

        class_names(
          'drawer-panel',
          'fixed top-0 h-full w-full',
          position_config[:side],
          SIZES.fetch(@size, SIZES[:medium]),
          'bg-base-100 shadow-2xl',
          'transform transition-transform duration-300 ease-in-out',
          position_config[:transform],
          'overflow-auto z-50'
        )
      end

      def panel_open_class
        position_settings[:open_class]
      end

      def title_id
        "#{drawer_id}-title"
      end

      def title?
        @title.present? || header?
      end

      def close_button_label
        t('.close_drawer')
      end

      private

      attr_reader :title, :options

      def position_settings
        POSITIONS.fetch(@position, POSITIONS[:right])
      end

      def html_attributes
        {
          id: drawer_id,
          class: drawer_classes,
          role: 'dialog',
          'aria-modal': 'true',
          'aria-labelledby': title? ? title_id : nil,
          data: default_data_attributes.merge(options.fetch(:data, {}))
        }.compact
      end

      def default_data_attributes
        {
          controller: 'drawer',
          drawer_target: 'template',
          action: 'keydown.esc->drawer#close'
        }
      end
    end
  end
end
