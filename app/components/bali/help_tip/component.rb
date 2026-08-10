# frozen_string_literal: true

module Bali
  module HelpTip
    # The help icon with a tooltip, packaged: the "?" next to a table header, a
    # label or a domain term is one component instead of a hand-rolled
    # Tooltip + Icon pair at every call site (#993 — one host had rewritten it
    # 49 times, once with the SVG copied inline). `FieldGroupWrapper` renders a
    # field's `tooltip:` option through this, so the help icon on a form field
    # and the one in a table cell are the same drawing.
    #
    # The balloon inherits Tooltip's portal default, so it escapes clipping
    # ancestors (the `<main>` overflow, a drawer) without any per-call opt-in.
    #
    # @example Plain text
    #   render Bali::HelpTip::Component.new(t('.sipoc_help'))
    #
    # @example Custom icon and placement
    #   render Bali::HelpTip::Component.new(text, icon: 'circle-help', placement: :right)
    #
    # @example Rich content, as a block
    #   render Bali::HelpTip::Component.new do
    #     tag.p "..."
    #   end
    class Component < ApplicationViewComponent
      ICON_CLASSES = "size-4 text-base-content/60"

      # @param text [String, nil] Balloon text. Alternatively pass a content block.
      # @param icon [String, Symbol] Icon name (Bali::Icon pipeline)
      # @param placement [Symbol] :top, :bottom, :left or :right
      # @param options [Hash] Passed through to Bali::Tooltip (append_to:, class:, data:, …)
      def initialize(text = nil, icon: "info-circle", placement: :top, **options)
        @text = text
        @icon = icon
        @placement = placement
        @options = options
      end

      def call
        render(Bali::Tooltip::Component.new(placement: @placement, **@options)) do |tooltip|
          tooltip.with_trigger do
            render(Bali::Icon::Component.new(@icon, class: ICON_CLASSES))
          end
          @text.presence || content
        end
      end
    end
  end
end
