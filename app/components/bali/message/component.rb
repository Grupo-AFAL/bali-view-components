# frozen_string_literal: true

module Bali
  module Message
    class Component < ApplicationViewComponent
      BASE_CLASSES = 'alert message-component'

      COLORS = {
        primary: 'alert-info',
        secondary: 'alert',
        success: 'alert-success',
        danger: 'alert-error',
        warning: 'alert-warning',
        info: 'alert-info',
        link: 'alert-info'
      }.freeze

      SIZES = {
        small: 'text-sm',
        regular: '',
        medium: 'text-base',
        large: 'text-lg'
      }.freeze

      STYLES = {
        soft: 'alert-soft',
        outline: 'alert-outline',
        dash: 'alert-dash'
      }.freeze

      renders_one :header

      def initialize(title: nil, size: :regular, color: :primary, style: nil, **options)
        @title = title
        @size = size&.to_sym
        @color = color&.to_sym
        @style = style&.to_sym
        @options = prepend_class_name(options, message_classes)
      end

      private

      attr_reader :title, :options

      def message_classes
        class_names(
          BASE_CLASSES,
          COLORS.fetch(@color, COLORS[:primary]),
          SIZES.fetch(@size, SIZES[:regular]),
          STYLES[@style]
        )
      end
    end
  end
end
