# frozen_string_literal: true

module Bali
  module Breadcrumb
    class Component < ApplicationViewComponent
      renders_many :items, Item::Component

      def initialize(**options)
        @options = options
      end

      # Translated aria-label for navigation
      def aria_label
        I18n.t("bali_view.breadcrumb.aria_label")
      end

      private

      def container_classes
        class_names(
          "breadcrumbs",
          "text-sm",
          "overflow-x-auto",
          @options[:class]
        )
      end
    end
  end
end
