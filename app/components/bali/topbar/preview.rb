# frozen_string_literal: true

module Bali
  module Topbar
    class Preview < ApplicationViewComponentPreview
      # @label Default
      # Topbar with all four zones populated: search, two icon actions, and a
      # user dropdown.
      def default
        render_with_template(template: 'bali/topbar/previews/default')
      end

      # @label Search Only
      # Minimal topbar with just a global search input.
      def search_only
        render_with_template(template: 'bali/topbar/previews/search_only')
      end

      # @label Without Search
      # Topbar without a search input — actions and user menu only.
      def without_search
        render_with_template(template: 'bali/topbar/previews/without_search')
      end

      # @label Without Mobile Trigger
      # Topbar for layouts that have no sidebar (no hamburger button).
      def without_mobile_trigger
        render_with_template(template: 'bali/topbar/previews/without_mobile_trigger')
      end
    end
  end
end
