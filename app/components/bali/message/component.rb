# frozen_string_literal: true

module Bali
  module Message
    class Component < ApplicationViewComponent
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

      attr_reader :title, :options

      renders_one :header

      def initialize(title: nil, size: :regular, color: :primary, **options)
        @title = title
        @size = size&.to_sym
        @color = color&.to_sym
        @options = prepend_class_name(options, message_classes)
      end

      def message_classes
        class_names(
          'alert message-component',
          COLORS[@color] || COLORS[:primary],
          SIZES[@size] || SIZES[:regular]
        )
      end
    end
  end
end
