# frozen_string_literal: true

module Bali
  module Tabs
    class Component < ApplicationViewComponent
      STYLES = {
        default: '',
        border: 'tabs-border',
        box: 'tabs-box',
        lift: 'tabs-lift'
      }.freeze

      SIZES = {
        xs: 'tabs-xs',
        sm: 'tabs-sm',
        md: '',
        lg: 'tabs-lg',
        xl: 'tabs-xl'
      }.freeze

      renders_many :tabs, Tab::Component

      def initialize(style: :border, size: :md, **options)
        @style = style&.to_sym
        @size = size&.to_sym
        @options = options

        @options = prepend_class_name(@options, 'tabs-component')
        @options = prepend_controller(@options, 'tabs')
      end

      private

      attr_reader :options

      def tabs_classes
        class_names(
          'tabs',
          STYLES.fetch(@style, ''),
          SIZES.fetch(@size, '')
        )
      end
    end
  end
end
