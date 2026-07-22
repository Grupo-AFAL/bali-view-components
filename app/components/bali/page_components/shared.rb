# frozen_string_literal: true

module Bali
  module PageComponents
    module Shared
      extend ActiveSupport::Concern

      private

      def breadcrumb_spacer_class
        "mt-1" unless breadcrumbs.empty?
      end

      def render_breadcrumbs
        return if breadcrumbs.empty?

        render(Bali::Breadcrumb::Component.new) do |bc|
          breadcrumbs.each { |crumb| bc.with_item(**crumb) }
        end
      end

      def render_actions_bar
        return unless actions?

        helpers.tag.div(class: "flex items-center gap-2 flex-wrap max-sm:w-full") do
          helpers.safe_join(actions)
        end
      end

      # Renders the optional nav slot (second-level navigation, e.g. Bali::Tabs)
      # between the PageHeader and the body with standardized spacing.
      def render_nav
        return unless nav?

        helpers.tag.div(class: "page-nav mt-4") { nav.to_s }
      end
    end
  end
end
