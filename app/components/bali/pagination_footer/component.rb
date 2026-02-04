# frozen_string_literal: true

module Bali
  module PaginationFooter
    # Standardized pagination footer with summary text and pagination controls.
    #
    # Renders a flex container with:
    # - Summary text on the left (e.g., "Showing 1-10 of 100 items")
    # - Pagination controls on the right (when multiple pages exist)
    #
    # @example Basic usage
    #   <%= render Bali::PaginationFooter::Component.new(pagy: @pagy) %>
    #
    # @example With custom item name
    #   <%= render Bali::PaginationFooter::Component.new(pagy: @pagy, item_name: 'studios') %>
    #
    # @example Hide summary
    #   <%= render Bali::PaginationFooter::Component.new(pagy: @pagy, show_summary: false) %>
    #
    class Component < ApplicationViewComponent
      # @param pagy [Pagy] Pagy object for pagination
      # @param item_name [String] Name for items in summary (default: 'items')
      # @param show_summary [Boolean] Whether to show summary text (default: true)
      # @param show_pagination [Boolean] Whether to show pagination controls (default: true)
      def initialize(pagy:, item_name: nil, show_summary: true, show_pagination: true)
        @pagy = pagy
        @item_name = item_name
        @show_summary = show_summary
        @show_pagination = show_pagination
      end

      def render?
        @pagy.present?
      end

      def summary_text
        I18n.t(
          'view_components.bali.pagination_footer.summary',
          from: @pagy.from,
          to: @pagy.to,
          count: @pagy.count,
          item_name: item_name,
          default: 'Showing %<from>s-%<to>s of %<count>s %<item_name>s'
        )
      end

      def show_pagination?
        @show_pagination && @pagy.pages > 1
      end

      def show_summary?
        @show_summary
      end

      private

      def item_name
        @item_name || I18n.t('view_components.bali.pagination_footer.default_item_name',
                             default: 'items')
      end
    end
  end
end
