# frozen_string_literal: true

module Bali
  module AppLayout
    class Component < ApplicationViewComponent
      renders_one :sidebar
      renders_one :topbar
      renders_one :body

      def initialize(**options)
        @options = options
      end

      def container_classes
        class_names(
          "app-layout",
          "flex",
          "min-h-screen",
          @options[:class]
        )
      end
    end
  end
end
