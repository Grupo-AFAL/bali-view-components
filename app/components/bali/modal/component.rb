# frozen_string_literal: true

module Bali
  module Modal
    class Component < ApplicationViewComponent
      def initialize(active: true, **options)
        @active = active
        @wrapper_class = options.delete(:wrapper_class)
        @options = options

        prepend_class_names
        prepend_data_attributes
      end

      private

      def prepend_class_names
        @options = prepend_class_name(@options, 'is-active') if @active
        @options = prepend_class_name(@options, 'modal-component modal')
      end
      
      def prepend_data_attributes
        @options = prepend_data_attribute(@options, 'modal-target', 'template')
      end
    end
  end
end
