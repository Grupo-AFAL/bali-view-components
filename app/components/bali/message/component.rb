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

      renders_one :header

      def initialize(title: nil, size: :regular, color: :primary, **options)
        @title = title
        @size = size&.to_sym
        @color = color&.to_sym
        @options = prepend_class_name(options, message_classes)
      end

      private

      attr_reader :title, :options

      def message_classes
        class_names(
          BASE_CLASSES,
          COLORS.fetch(@color, COLORS[:primary]),
          SIZES.fetch(@size, SIZES[:regular])
        )
      end
    end
  end
end
