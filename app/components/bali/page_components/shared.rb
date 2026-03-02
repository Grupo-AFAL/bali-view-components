# frozen_string_literal: true

module Bali
  module PageComponents
    module Shared
      extend ActiveSupport::Concern

      private

      def parse_breadcrumbs(breadcrumbs)
        breadcrumbs.map(&:symbolize_keys)
      end

      def breadcrumb_spacer_class
        "mt-4" if @breadcrumbs.any?
      end

      def render_breadcrumbs
        return unless @breadcrumbs.any?

        render(Bali::Breadcrumb::Component.new) do |bc|
          @breadcrumbs.each { |crumb| bc.with_item(**crumb) }
        end
      end

      def render_actions_bar
        return unless actions?

        tag.div(class: "flex items-center gap-2") { safe_join(actions) }
      end
    end
  end
end
