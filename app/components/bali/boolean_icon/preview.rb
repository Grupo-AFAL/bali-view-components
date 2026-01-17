# frozen_string_literal: true

module Bali
  module BooleanIcon
    class Preview < ApplicationViewComponentPreview
      # @param value toggle
      # Displays a boolean value as a colored icon.
      # Use in table cells or lists to show status at a glance.
      def default(value: true)
        render Bali::BooleanIcon::Component.new(value: value)
      end

      # @label All States
      # Shows true, false, and nil values side-by-side for comparison.
      # Nil values are treated as false.
      def all_states
        render_with_template
      end
    end
  end
end
