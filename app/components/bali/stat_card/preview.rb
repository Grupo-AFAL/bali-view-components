# frozen_string_literal: true

module Bali
  module StatCard
    class Preview < Lookbook::Preview
      # @param title text
      # @param value text
      # @param icon_name text
      # @param color select { choices: [primary, secondary, accent, success, warning, error, info] }
      def default(title: 'Total Users', value: '1,234', icon_name: 'users', color: :primary)
        render Bali::StatCard::Component.new(
          title: title,
          value: value,
          icon_name: icon_name,
          color: color.to_sym
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
