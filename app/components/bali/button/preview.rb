# frozen_string_literal: true

module Bali
  module Button
    class Preview < ApplicationViewComponentPreview
      # @param variant select { choices: [primary, secondary, accent, info, success, warning, error, ghost, link, neutral, outline] }
      # @param size select { choices: [xs, sm, md, lg, xl] }
      # @param disabled toggle
      # @param loading toggle
      def default(variant: :primary, size: :md, disabled: false, loading: false)
        render Bali::Button::Component.new(
          name: 'Button',
          variant: variant.to_sym,
          size: size.to_sym,
          disabled: disabled,
          loading: loading
        )
      end

      # With Icon
      # ---------------
      # When `responsive: true` (default), the label hides on mobile and the button becomes
      # a square icon-only button using DaisyUI's `max-sm:btn-square`.
      # @param responsive toggle
      def with_icon(responsive: true)
        render Bali::Button::Component.new(name: 'Add Item', variant: :primary, icon_name: 'plus', responsive: responsive)
      end

      # @label Button Group
      # Shows buttons grouped together with consistent spacing
      def button_group
        render_with_template
      end
    end
  end
end
