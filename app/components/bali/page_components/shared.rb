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

      def render_sidebar_layout(main_content, sidebar_content = nil)
        if sidebar_content
          tag.div(class: "grid grid-cols-1 lg:grid-cols-3 gap-6") do
            safe_join([
              tag.div(main_content, class: "lg:col-span-2"),
              tag.div(sidebar_content, class: "space-y-6")
            ])
          end
        else
          main_content
        end
      end
    end
  end
end
