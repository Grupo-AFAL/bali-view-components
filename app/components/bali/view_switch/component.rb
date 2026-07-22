# frozen_string_literal: true

module Bali
  module ViewSwitch
    # Segmented control (DaisyUI `join` of buttons) to switch between sibling
    # views of the same content (list / table / board / schedule). Each view is
    # a real link — the selected view is expected to travel in the PATH so GET
    # filter forms don't lose it.
    class Component < ApplicationViewComponent
      renders_many :views, ->(name:, icon:, href:, active: nil, **options) do
        View::Component.new(
          name: name,
          icon: icon,
          href: href,
          active: active,
          icon_only: @icon_only,
          size: @size,
          **options
        )
      end

      # @param aria_label [String] Accessible label for the group of buttons
      # @param size [Symbol] Button size (:xs, :sm, :md, :lg, :xl)
      # @param icon_only [Boolean] Render square icon-only buttons; each view's
      #   name becomes the native tooltip (title) and the accessible label
      def initialize(aria_label:, size: :sm, icon_only: false, **options)
        @aria_label = aria_label
        @size = size&.to_sym
        @icon_only = icon_only

        @options = prepend_class_name(options, "view-switch-component join")
      end

      private

      attr_reader :aria_label, :options

      def container_attributes
        { role: "group", "aria-label": aria_label }.merge(options)
      end
    end
  end
end
