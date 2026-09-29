# frozen_string_literal: true

module Bali
  module DataTable
    # What a listing's URL looks like when ONE of the toolbar's navigation controls changes
    # (group by, view switch), or when what is on screen is exported: the current query string
    # is merged and only that param changes, so filters, search, sorting and the applied saved
    # view survive the click.
    #
    # It is shared because the two separate derivations had already diverged: the listing's
    # `url:` CAN carry a query string (a host passing `request.fullpath`, or a path helper
    # with params — Export, SavedViews and Filters already account for it), and concatenating
    # a bare "?" produced `/movies?scope=x?view=grid`, which Rack parses as a single corrupt
    # param with no `view`: the click did not switch views and dirtied the scope as well.
    module ToolbarHref
      # One-shot orders: they are ACTIONS, not navigation state — dragging them along re-runs
      # the clearing on every later click (`clear_filters` also DELETES the user's filter
      # cache on the server: `Rails.cache.delete(cache_key)`). `page` is dropped because
      # switching view or grouping goes back to the first page, and because an export that
      # takes `page` along exports ONE page instead of the set.
      #
      # TWIN IN JS: `export_links_controller.js` drops exactly this list when re-syncing the ⋯
      # hrefs from `window.location`. Moving a param here without moving it there leaves the
      # two halves of the same link in disagreement.
      TRANSIENT_PARAMS = %w[page clear_filters clear_search].freeze

      # @param url [String] Base URL of the listing, with or without a query string
      # @param current_params [Hash] current query params, preserved in the link
      # @param param [String, Symbol] param this control changes
      # @param value [String, nil] new value; `nil` takes it out of the URL
      def build_toolbar_href(url, current_params, param, value)
        base, base_query = url.to_s.split("?", 2)
        key = param.to_s
        params = Rack::Utils.parse_nested_query(base_query.to_s)
          .merge((current_params || {}).to_h.stringify_keys)
          .except(*TRANSIENT_PARAMS, key)
        params[key] = value unless value.nil?

        query = params.to_query
        query.present? ? "#{base}?#{query}" : base
      end

      # The slice the user is looking at, or `{}` with no request context (previews,
      # `render_inline`). It lives here and not as a private method of the DataTable because
      # the export is painted OUTSIDE the component —in the PageHeader's ⋯— and has to read
      # the same state without anyone passing it in.
      def request_query_params
        helpers.request.query_parameters.to_h
      rescue StandardError
        {}
      end
    end
  end
end
