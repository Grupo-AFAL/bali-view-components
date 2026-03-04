# frozen_string_literal: true

module Bali
  module AppLayout
    class Component < ApplicationViewComponent
      renders_one :banner
      renders_one :navbar
      renders_one :sidebar
      renders_one :topbar
      renders_one :body

      BODY_CONTAINER_PRESETS = {
        wide:      { padding: :md },
        contained: { max_width: "7xl", padding: :md_x, center: true },
        narrow:    { max_width: "xl", padding: :sm_x, center: true },
        full:      {}
      }.freeze

      PADDING_MAP = {
        none: "",
        sm: "p-4",
        sm_x: "px-4",
        md: "p-6",
        md_x: "px-6",
        lg: "p-8",
        lg_x: "px-8"
      }.freeze

      def initialize(fixed_sidebar: false, flash: nil, modal: true, drawer: true, body_class: nil, body_container: :wide, data: {}, **options)
        @fixed_sidebar = fixed_sidebar
        @flash = flash
        @modal = normalize_shell_option(modal)
        @drawer = normalize_shell_option(drawer)
        @body_class = body_class
        @body_container = resolve_body_container(body_container)
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

      def body_container_classes
        config = @body_container
        classes = [ "app-layout-body-container" ]

        classes << "max-w-#{config[:max_width]}" if config[:max_width].present?
        classes << PADDING_MAP[config[:padding].to_sym] if config[:padding].present?
        classes << "mx-auto" if config[:center]

        class_names(*classes)
      end

      def main_controller
        controllers = []
        controllers << "modal" if @modal
        controllers << "drawer" if @drawer
        controllers.join(" ")
      end

      private

      def resolve_body_container(value)
        case value
        when Symbol
          BODY_CONTAINER_PRESETS.fetch(value, BODY_CONTAINER_PRESETS[:wide]).dup
        when Hash
          base = value[:preset] ? BODY_CONTAINER_PRESETS.fetch(value[:preset].to_sym, {}).dup : {}
          base.merge(value.except(:preset))
        when false
          BODY_CONTAINER_PRESETS[:full].dup
        else
          BODY_CONTAINER_PRESETS[:wide].dup
        end
      end

      def normalize_shell_option(value)
        case value
        when true then {}
        when Hash then value
        when false, nil then false
        else
          raise ArgumentError, "Expected true, false, or Hash, got #{value.inspect}"
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
