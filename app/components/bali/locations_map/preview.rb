# frozen_string_literal: true

module Bali
  module LocationsMap
    class Preview < ApplicationViewComponentPreview
      LOCATIONS = [
        { latitude: 32.52535328002182, longitude: -117.01662677673296 },
        { latitude: 32.528469988815075, longitude: -117.0197954175343, color: 'green' },
        { latitude: 32.53146597286308, longitude: -117.02884042070805, color: '#f98f00',
          glyph_color: '#feddae', border_color: '#ea6200' },
        { latitude: 32.52900375149942, longitude: -117.0356861180097, color: '#f98f00',
          glyph_color: 'white', border_color: '#ea6200', label: 1 },
        { latitude: 32.52284404972829, longitude: -117.0330700546029,
          icon_url: 'https://maps.google.com/mapfiles/kml/paddle/blu-blank.png' }
      ].freeze

      # @label Default
      # Displays an interactive Google Map with location markers.
      #
      # ## Setup Required
      # This component requires a Google Maps JavaScript API key, read from
      # `Bali.google_maps_key`:
      # ```ruby
      # Bali.google_maps_key = Rails.application.credentials.dig(:google, :maps_key)
      # ```
      # With nothing configured it falls back to the `GOOGLE_MAPS_KEY`
      # environment variable. Without either, the component still renders and
      # the map area stays blank — the missing key is reported in the browser
      # console, not by a server-side error.
      # See [External Services Guide](/docs/guides/external-services.md) for setup instructions.
      #
      # @param zoom number
      # @param clustered toggle
      def default(zoom: 12, clustered: false)
        render Bali::LocationsMap::Component.new(zoom: zoom, clustered: clustered) do |c|
          LOCATIONS.each do |location_attrs|
            c.with_location(**location_attrs)
          end

          c.with_location(latitude: 32.516284591574724, longitude: -117.0129754500983) do |location|
            location.with_info_view { tag.p('This is an info view') }
          end
        end
      end

      # @label Fitted to locations
      # With `fit_to_locations: true` the map frames every marker instead of
      # trusting `center_*`/`zoom:` — no more guessing a center that lands in
      # the middle of nowhere when locations are far apart. `zoom:` becomes the
      # ceiling the map never zooms in past, which is what keeps a single
      # location (or a very tight cluster) from landing at street level.
      # @param zoom number
      # @param single toggle
      def fitted(zoom: 12, single: false)
        locations = single ? [LOCATIONS.first] : LOCATIONS

        render Bali::LocationsMap::Component.new(zoom: zoom, fit_to_locations: true) do |c|
          locations.each do |location_attrs|
            c.with_location(**location_attrs)
          end
        end
      end

      # @label With Cards
      # Displays location cards alongside the map. Cards highlight when clicking markers.
      # @param zoom number
      # @param clustered toggle
      def with_cards(zoom: 12, clustered: false)
        render Bali::LocationsMap::Component.new(zoom: zoom, clustered: clustered) do |c|
          LOCATIONS.each_with_index do |location_attrs, index|
            c.with_card(**location_attrs) { tag.p("Card #{index + 1}") }
            c.with_location(**location_attrs)
          end

          c.with_card(latitude: 32.516284591574724, longitude: -117.0129754500983) do
            tag.p('Card with info view')
          end

          c.with_location(latitude: 32.516284591574724, longitude: -117.0129754500983) do |location|
            location.with_info_view { tag.p('This is an info view') }
          end
        end
      end
    end
  end
end
