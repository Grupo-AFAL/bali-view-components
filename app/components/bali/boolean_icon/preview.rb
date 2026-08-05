# frozen_string_literal: true

module Bali
  module BooleanIcon
    class Preview < ApplicationViewComponentPreview
      # @param value toggle
      # Displays a boolean value as a coloured icon plus an `sr-only` name, so a
      # screen reader announces "Yes"/"No" where a sighted reader sees the icon.
      # Use in table cells or lists to show status at a glance.
      def default(value: true)
        render Bali::BooleanIcon::Component.new(value: value)
      end

      # @label All States
      # true, false and nil side by side. `nil` is missing data, not false: it
      # renders a neutral dash and announces "Not specified".
      def all_states
        render_with_template
      end

      # @label With Label
      # The default name is correct but context-free — "Yes" on its own says
      # nothing about what is true. Pass `label:` when the surrounding markup
      # does not supply the subject.
      def with_label
        render Bali::BooleanIcon::Component.new(value: true, label: 'Indie film: yes')
      end
    end
  end
end
