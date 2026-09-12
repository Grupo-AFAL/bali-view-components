# frozen_string_literal: true

module Bali
  module ReactIsland
    # @label React Island
    class Preview < ApplicationViewComponentPreview
      # The official mechanism for mounting React inside a Hotwire app
      # (`bali-view-components/react-island`) — see `docs/api/react-island.md`.
      # There is no Ruby component: the host renders a `data-controller` element
      # and a Stimulus controller subclassing `ReactIslandController` mounts the
      # React component on it.
      #
      # The counter here is a toy island defined in the dummy app
      # (`spec/dummy/app/javascript/islands/CounterIsland.jsx`). Its bundle is
      # NOT part of the main JS: `startIslandLoader('react-island-demo')`
      # injects it on demand from the paths published by
      # `react_island_meta_tags` — the exact wiring a host app uses.
      #
      # The "Explode" button throws during render on purpose: it demonstrates
      # the built-in ErrorBoundary (the island is replaced by a fallback and
      # the configurable `onError` hook fires).
      # @param label text
      # @param start number
      def default(label: "Visitors", start: 3)
        render_with_template(locals: { label: label, start: start.to_i })
      end

      # @label Two Islands + Turbo Navigation
      # Two independent islands on one page, each with its own props and React
      # root, plus a Turbo link to another island page. Navigating must mount
      # each island exactly once — the entry's registration guard is what
      # prevents the double-mount bug afal-apps shipped by starting a second
      # Stimulus Application.
      def two_islands
        render_with_template
      end

      # @label Load Error Fallback
      # The controller's `loadComponent()` throws here (simulating a bundle
      # that fails to load), so the island renders the `errorFallback` message
      # instead of white space, and reports through the `onError` hook.
      def load_error
        render_with_template
      end
    end
  end
end
