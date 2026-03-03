# frozen_string_literal: true

module Bali
  module AppLayout
    class Component < ApplicationViewComponent
      renders_one :banner
      renders_one :navbar
      renders_one :sidebar
      renders_one :topbar
      renders_one :body

      def initialize(fixed_sidebar: false, flash: nil, modal: true, drawer: true, body_class: nil, data: {}, **options)
        @fixed_sidebar = fixed_sidebar
        @flash = flash
        @modal = normalize_shell_option(modal)
        @drawer = normalize_shell_option(drawer)
        @body_class = body_class
        @data = data
        @options = options
      end

      def container_classes
        class_names(
          "app-layout",
          "flex flex-col",
          "min-h-screen",
          { "app-layout--has-fixed-sidebar" => @fixed_sidebar && sidebar? },
          { "app-layout--has-navbar" => navbar? },
          { "app-layout--has-sidebar" => sidebar? },
          @body_class,
          @options[:class]
        )
      end

      def container_data_attributes
        @data.present? ? { data: @data } : {}
      end

      def render_toast?
        @flash.present?
      end

      def render_modal?
        @modal
      end

      def render_drawer?
        @drawer
      end

      def main_controller
        controllers = []
        controllers << "modal" if @modal
        controllers << "drawer" if @drawer
        controllers.join(" ")
      end

      private

      def normalize_shell_option(value)
        case value
        when true then {}
        when Hash then value
        end
      end

      def flash_notice
        @flash&.[](:notice)
      end

      def flash_alert
        @flash&.[](:alert)
      end
    end
  end
end
