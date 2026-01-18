# frozen_string_literal: true

module Bali
  module Stepper
    class Preview < ApplicationViewComponentPreview
      # @param current select [0, 1, 2, 3]
      # @param orientation select [horizontal, vertical]
      # @param color select [primary, secondary, accent, neutral, info, success, warning, error]
      def default(current: 1, orientation: :horizontal, color: :primary)
        render Bali::Stepper::Component.new(
          current: current.to_i,
          orientation: orientation.to_sym,
          color: color.to_sym
        ) do |c|
          c.with_step(title: 'Register')
          c.with_step(title: 'Choose plan')
          c.with_step(title: 'Purchase')
          c.with_step(title: 'Receive product')
        end
      end

      # Vertical orientation
      # --------------------
      # Steps displayed vertically for sidebar or mobile layouts
      def vertical
        render Bali::Stepper::Component.new(current: 2, orientation: :vertical) do |c|
          c.with_step(title: 'Register')
          c.with_step(title: 'Choose plan')
          c.with_step(title: 'Purchase')
          c.with_step(title: 'Receive product')
        end
      end

      # Color variants
      # --------------
      # Different color schemes for different contexts
      def colors
        render_with_template
      end
    end
  end
end
