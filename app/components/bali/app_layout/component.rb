# frozen_string_literal: true

module Bali
  module AppLayout
    # Renders the <body> element directly. Intended for use in layout files
    # between <head> and </html>. Do NOT nest inside another <body> tag.
    class Component < ApplicationViewComponent
      renders_one :banner
      renders_one :navbar
      renders_one :sidebar
      renders_one :topbar
      renders_one :body

      BODY_CONTAINERS = {
        wide:      "p-6",
        contained: "max-w-7xl px-6 mx-auto",
        narrow:    "max-w-xl px-4 mx-auto",
        full:      ""
      }.freeze

      def initialize(fixed_sidebar: false, flash: nil, modal: true, drawer: true,
                     modal_size: nil, drawer_size: nil,
                     body_container: :wide, **options)
        @fixed_sidebar = fixed_sidebar
        @flash = flash
        @modal = modal
        @drawer = drawer
        @modal_size = modal_size
        @drawer_size = drawer_size
        @body_container = body_container
        @options = options
      end

      private

      def container_classes
        class_names(
          "app-layout",
          "flex flex-col",
          "min-h-screen",
          { "app-layout--has-fixed-sidebar" => @fixed_sidebar && sidebar? },
          { "app-layout--has-navbar" => navbar? },
          { "app-layout--has-sidebar" => sidebar? },
          @options[:class]
        )
      end

      def container_attributes
        @options.except(:class)
      end

      def render_toast?
        @flash.present?
      end

      def body_container_classes
        class_names(
          "app-layout-body-container",
          BODY_CONTAINERS.fetch(@body_container)
        )
      end

      def main_attributes
        controllers = []
        controllers << "modal" if @modal
        controllers << "drawer" if @drawer
        return {} if controllers.empty?

        { data: { controller: controllers.join(" ") } }
      end

      def flash_notice
        @flash&.dig(:notice)
      end

      def flash_alert
        @flash&.dig(:alert)
      end
    end
  end
end
