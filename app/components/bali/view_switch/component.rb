# frozen_string_literal: true

module Bali
  module ViewSwitch
    # Segmented control (DaisyUI `join` of buttons) to switch between sibling
    # views of the same content (list / table / board / schedule). Each view is
    # a real link — the selected view is expected to travel in the PATH so GET
    # filter forms don't lose it.
    #
    # `mode: :selector` covers the second job the same control does in the apps:
    # slicing the data shown (12/24/36 months, optimistic/pessimistic scenario)
    # instead of switching between sibling pages. The links still navigate (the
    # slice travels in the query string); only the semantics of the active item
    # change — `aria-current="true"` ("the current item of a set") instead of
    # `aria-current="page"`. Never `aria-pressed`: the browser discards it on a
    # link, see View::Component.
    class Component < ApplicationViewComponent
      renders_many :views, ->(name:, icon: nil, href:, active: nil, **options) do
        View::Component.new(
          name: name,
          icon: icon,
          href: href,
          active: active,
          icon_only: @icon_only,
          size: @size,
          mode: @mode,
          **options
        )
      end

      # @param aria_label [String] Accessible label for the group of buttons
      # @param size [Symbol] Button size (:xs, :sm, :md, :lg, :xl)
      # @param icon_only [Boolean, Symbol] Render square icon-only buttons; each view's
      #   name becomes the native tooltip (title) and the accessible label.
      #   `:responsive` only collapses the label below `sm`, keeping title/aria-label
      #   at every size (used by DataTable, where the switch shrinks instead of
      #   collapsing into the overflow menu)
      # @param mode [Symbol] `:navigation` (default) for sibling views of the same
      #   content — active view gets `aria-current="page"`. `:selector` for a control
      #   that slices the data shown (year, scenario, window) — active view gets
      #   `aria-current="true"`
      def initialize(aria_label:, size: :sm, icon_only: false, mode: :navigation, **options)
        @aria_label = aria_label
        @size = size&.to_sym
        @icon_only = icon_only
        @mode = mode&.to_sym

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
