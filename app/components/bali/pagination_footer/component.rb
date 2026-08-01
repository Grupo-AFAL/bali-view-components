# frozen_string_literal: true

module Bali
  module PaginationFooter
    # The one summary + controls block in the library.
    #
    # Renders a flex container with:
    # - Summary text on the left (e.g., "Showing 1-10 of 100 items")
    # - Pagination controls on the right (when there is more than one page)
    #
    # `Bali::DataTable` renders this instead of an inline copy of it; anything that needs a
    # listing footer should do the same rather than rebuild the pair.
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
    # @example Paging inside a Turbo Frame, without jumping to the top of the page
    #   <%= render Bali::PaginationFooter::Component.new(
    #         pagy: @pagy, fragment: '#movies', data: { turbo_frame: 'movies' }) %>
    #
    # @example Replacing the controls with your own
    #   <%= render Bali::PaginationFooter::Component.new(pagy: @pagy) do |footer| %>
    #     <% footer.with_controls { pagy_nav(@pagy) } %>
    #   <% end %>
    class Component < ApplicationViewComponent
      # The layout is the same wherever this band renders; the box around it is not, so the
      # two live apart. Passing spacing in through `class:` instead would land `py-4` and
      # `pt-4` on the same element — `pt-4` redundant, and `py-4` adding a bottom padding the
      # caller never asked for, because Tailwind resolves that pair by stylesheet order and
      # not by the order you wrote the classes in.
      LAYOUT_CLASSES = "flex flex-col sm:flex-row items-center justify-between"

      # Standing on its own, the band pads itself on both sides.
      SPACING_CLASSES = "gap-2 py-4"

      # Sitting under a rule at the foot of a listing, the breathing room goes above the line:
      # the listing already ends where it ends, and a bottom padding here only pushes whatever
      # follows further down.
      DIVIDED_CLASSES = "gap-4 mt-4 pt-4 border-t border-base-200"

      # Replaces `Bali::Pagination::Component` on the right-hand side. Declaring it does not
      # change the summary.
      renders_one :controls

      # @param pagy [Pagy] Pagy object for pagination
      # @param item_name [String] Name for items in summary (i18n default)
      # @param show_summary [Boolean] Whether to show summary text (default: true)
      # @param show_pagination [Boolean] Whether to show pagination controls (default: true)
      # @param size [Symbol] Button size forwarded to Pagination - :xs, :sm, :md, :lg
      # @param variant [Symbol] Button variant forwarded to Pagination - :default, :outline,
      #   :ghost
      # @param url [String] Base URL forwarded to Pagination (see that component for when it
      #   is needed)
      # @param fragment [String] Anchor forwarded to Pagination, appended to every page link
      # @param data [Hash] data attributes forwarded to every page link (not to the wrapper —
      #   the links are what a host wants to reach with `turbo_frame:`)
      # @param divider [Boolean] Sit under a rule at the foot of a listing instead of standing
      #   on its own: the space moves above the line and a `border-t` draws it (default: false)
      # @param options [Hash] Additional HTML attributes for the wrapper div
      def initialize(pagy:, item_name: nil, show_summary: true, show_pagination: true,
                     size: :md, variant: :default, url: nil, fragment: nil, data: nil,
                     divider: false, **options)
        @pagy = pagy
        @item_name = item_name
        @show_summary = show_summary
        @show_pagination = show_pagination
        @size = size
        @variant = variant
        @url = url
        @fragment = fragment
        @data = data
        @options = prepend_class_name(
          options, "#{LAYOUT_CLASSES} #{divider ? DIVIDED_CLASSES : SPACING_CLASSES}"
        )
      end

      # `render?` asks whether the `controls` slot was declared, and a slot declared inside
      # the render block does not exist until that block runs. ViewComponent only runs it
      # lazily, on the first `content` call — which for this template would be never.
      def before_render
        content
      end

      # An empty footer is not a footer. Without a Pagy there is nothing to say, and with a
      # Pagy whose summary and controls are both suppressed there is nothing to draw either —
      # the old version still emitted the flex container and its vertical padding.
      def render?
        @pagy.present? && (show_summary? || show_controls?)
      end

      def summary_text
        adapter.summary(@item_name)
      end

      def show_summary?
        @show_summary && adapter.summarizable?
      end

      # Custom controls render whenever they are declared: a host that hands us its own nav
      # decided for itself what a single page should look like.
      def show_controls?
        @show_pagination && (controls? || adapter.navigable?)
      end

      def pagination
        Bali::Pagination::Component.new(
          pagy: @pagy, size: @size, variant: @variant, url: @url,
          fragment: @fragment, data: @data
        )
      end

      private

      def adapter
        @adapter ||= Bali::Pagination::PagyAdapter.new(@pagy)
      end
    end
  end
end
