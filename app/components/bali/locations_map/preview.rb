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

      # The `locale:` keyword below goes unread: the dummy's ComponentPreviewsController
      # applies `?locale=` to the whole request. Lookbook raises "Unknown method parameter" for an
      # `@param` the method does not take.

      # @label Default
      # Displays an interactive Google Map with location markers.
      #
      # ## Setup Required
      # This component requires a Google Maps JavaScript API key, read from
      # `Bali.google_maps.api_key`:
      # ```ruby
      # Bali.google_maps.api_key = Rails.application.credentials.dig(:google, :maps_key)
      # ```
      # and handed to every map on the page, with `Bali.google_maps.map_id`, from the layout's
      # `<head>`:
      # ```erb
      # <%= google_maps_meta_tags %>
      # ```
      # With nothing configured it falls back to the `GOOGLE_MAPS_KEY`
      # environment variable. Without either, the component renders nothing, so
      # the page can show the coordinates in its place. The dummy's own key is a
      # stub unless the shell exports a real one, and Google answers it with
      # "Oops! Something went wrong."
      # See [External Services Guide](/docs/guides/external-services.md) for setup instructions.
      #
      # The map's labels are in the language of the `<html lang>`, which the dummy writes from
      # the request's locale: switch `locale` to see them in Spanish.
      #
      # @param zoom number
      # @param clustered toggle
      # @param locale select { choices: [en, es] }
      def default(zoom: 12, clustered: false, locale: 'en')
        render_with_template(
          template: 'bali/locations_map/previews/default',
          locals: { zoom: zoom, clustered: clustered, locations: Bali::LocationsMap::Preview::LOCATIONS }
        )
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

      # @label Small
      # A map small enough to confirm one point inside a card. `map_class:` lands
      # on the map, 450px tall by default, and a height there wins without `!`.
      # @param map_class select { choices: [h-56, h-96] }
      def small(map_class: 'h-56')
        render Bali::LocationsMap::Component.new(zoom: 15, fit_to_locations: true, map_class: map_class) do |c|
          c.with_location(**LOCATIONS.first)
        end
      end

      # @label Following inputs
      # The markers follow `data-locations-map-locations-value` once the map
      # has connected: the page writes it, here from two inputs, as an array
      # of `{ lat, lng }` plus any of `name`, `markerColor`, `markerLabel`,
      # `markerUrl`, `markerBorderColor` and `markerGlyphColor`. While the
      # value is on the element, it replaces the locations rendered with
      # `with_location`.
      def following_inputs
        render_with_template(
          template: 'bali/locations_map/previews/following_inputs',
          locals: { location: LOCATIONS.first }
        )
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
