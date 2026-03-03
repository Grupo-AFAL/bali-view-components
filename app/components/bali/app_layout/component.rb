# frozen_string_literal: true

module Bali
  module AppLayout
    class Component < ApplicationViewComponent
      renders_one :sidebar
      renders_one :topbar
      renders_one :body

      def initialize(fixed_sidebar: false, flash: nil, modal: true, drawer: true, **options)
        @fixed_sidebar = fixed_sidebar
        @flash = flash
        @modal = normalize_shell_option(modal)
        @drawer = normalize_shell_option(drawer)
        @options = options
      end

      def container_classes
        class_names(
          "app-layout",
          "flex",
          "min-h-screen",
          { "app-layout--has-fixed-sidebar" => @fixed_sidebar },
          @options[:class]
        )
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
