# frozen_string_literal: true

module Bali
  module Dropdown
    class Component < ApplicationViewComponent
      ALIGNMENTS = {
        left: "",
        right: "dropdown-end",
        top: "dropdown-top",
        bottom: "dropdown-bottom",
        top_end: "dropdown-top dropdown-end",
        bottom_end: "dropdown-bottom dropdown-end"
      }.freeze

      renders_one :trigger, Trigger::Component
      renders_many :items, ->(method: :get, href: nil, tag: :link, **options) do
        if tag == :button
          ActionItem::Component.new(**options)
        else
          component_klass = method&.to_sym == :delete ? DeleteLink::Component : Link::Component
          options[:role] ||= "menuitem"
          component_klass.new(
            method: method, href: href, plain: true,
            **prepend_class_name(options, "menu-item w-full text-left")
          )
        end
      end

      def initialize(hoverable: false, close_on_click: true, align: :right, wide: false, **options)
        @hoverable = hoverable
        @close_on_click = close_on_click
        @align = align&.to_sym
        @wide = wide
        @options = options
      end

      def content_classes
        class_names(
          "dropdown-content",
          "menu",
          "bg-base-100",
          "text-base-content", # Ensure proper text contrast regardless of parent colors
          "rounded-box",
          "z-50",
          "shadow-lg",
          "p-2",
          @wide ? "w-80" : "w-52"
        )
      end

      def render?
        items? ? items.any?(&:authorized?) : content.present?
      end

      private

      def dropdown_classes
        class_names(
          "dropdown",
          ALIGNMENTS[@align],
          "dropdown-hover" => @hoverable
        )
      end

      def dropdown_attributes
        attrs = @options.merge(class: class_names(dropdown_classes, @options[:class]))
        unless @hoverable
          attrs[:data] = (attrs[:data] || {}).merge(
            controller: [ "dropdown", attrs.dig(:data, :controller) ].compact.join(" "),
            dropdown_close_on_click_value: @close_on_click
          )
        end
        attrs
      end
    end
  end
end
