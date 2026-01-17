# frozen_string_literal: true

module Bali
  module Breadcrumb
    class Component < ApplicationViewComponent
      renders_many :items, Item::Component

      def initialize(**options)
        @options = options
      end

      private

      def container_classes
        class_names(
          'breadcrumbs',
          'text-sm',
          @options[:class]
        )
      end
    end
  end
end
