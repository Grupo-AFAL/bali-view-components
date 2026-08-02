# frozen_string_literal: true

module Bali
  module StatCard
    class Preview < ApplicationViewComponentPreview
      # @param title text
      # @param value text
      # @param icon text
      # @param color select { choices: [neutral, primary, secondary, accent, info, success, warning, error, ghost] }
      def default(title: 'Total Users', value: '1,234', icon: 'users', color: :primary)
        render Bali::StatCard::Component.new(
          title: title,
          value: value,
          icon: icon,
          color: color.to_sym
        )
      end

      # The hex escape hatch. `custom_color:` replaces the semantic pair with an
      # inline colour, so it stops following the theme — that is the trade.
      # @param custom_color text
      def with_custom_color(custom_color: '#7c3aed')
        render Bali::StatCard::Component.new(
          title: 'Brand Signups',
          value: '312',
          icon: 'user-plus',
          custom_color: custom_color
        )
      end

      # With footer showing a trend
      def with_trend
        render_with_template(template: 'bali/stat_card/previews/with_trend')
      end

      # With footer showing status
      def with_status
        render_with_template(template: 'bali/stat_card/previews/with_status')
      end
    end
  end
end
