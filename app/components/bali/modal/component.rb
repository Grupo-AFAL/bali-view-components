# frozen_string_literal: true

module Bali
  module Modal
    class Component < ApplicationViewComponent
      SIZES = {
        sm: 'max-w-sm',
        md: 'max-w-md',
        lg: 'max-w-lg',
        xl: 'max-w-xl',
        full: 'max-w-full'
      }.freeze

      def initialize(active: true, size: nil, **options)
        @active = active
        @size = size&.to_sym
        @wrapper_class = options.delete(:wrapper_class)
        @options = options
      end

      def modal_classes
        class_names(
          'modal-component',
          'modal',
          @active && 'modal-open',
          @options[:class]
        )
      end

      def box_classes
        class_names(
          'modal-box',
          SIZES[@size],
          @wrapper_class
        )
      end

      def stimulus_controller
        'modal'
      end
    end
  end
end
