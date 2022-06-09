# frozen_string_literal: true

module Bali
  module Drawer
    class Component < Bali::Modal::Component

      private

      def prepend_class_names
        @options = prepend_class_name(@options, 'is-active') if @active
        @options = prepend_class_name(@options, 'drawer-component modal drawer')
      end
      
      def prepend_data_attributes
        @options = prepend_data_attribute(@options, 'drawer-target', 'template')
      end
    end
  end
end