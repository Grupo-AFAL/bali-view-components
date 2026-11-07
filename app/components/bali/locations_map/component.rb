# frozen_string_literal: true

module Bali
  module LocationsMap
    class Component < ApplicationViewComponent
      # Default center: Tijuana, Mexico (can be overridden via center_latitude/center_longitude)
      DEFAULT_CENTER_LAT = 32.5036383
      DEFAULT_CENTER_LNG = -117.0308968

      BASE_CLASSES = "locations-map-component flex max-md:flex-col"
      MAP_CLASSES = "location-map"
      CARDS_WRAPPER_CLASSES = "locations-map-component--cards flex-1 mr-3 max-md:mr-0"
      LOCATIONS_WRAPPER_CLASSES = "locations-map-component--locations flex-1 ml-3 " \
                                  "max-md:ml-0 max-md:mt-6"

      renders_many :cards, Card::Component
      renders_many :locations, Location::Component

      # fit_to_locations: frame every location instead of trusting center/zoom —
      # with it, `zoom:` becomes the ceiling the map never zooms in past (what a
      # single location would otherwise do), and `center_*` only paints the first
      # frame before the fit resolves.
      #
      # @param map_class [String, nil] Classes for the map itself, 450px tall by default:
      #   `map_class: "h-56"` makes it shorter, without `!`.
      def initialize(
        center_latitude: DEFAULT_CENTER_LAT,
        center_longitude: DEFAULT_CENTER_LNG,
        zoom: 12,
        clustered: false,
        fit_to_locations: false,
        map_class: nil,
        **options
      )
        @center_latitude = center_latitude
        @center_longitude = center_longitude
        @zoom = zoom
        @clustered = clustered
        @fit_to_locations = fit_to_locations
        @map_class = map_class
        @options = options
      end

      # Without a key Google paints a darkened map under a "This page can't load Google Maps
      # correctly" dialog, and logs the error. The log line is what is left to tell a missing key
      # from a page with no map on it.
      def render?
        return true if Bali.google_maps.api_key.present?

        Rails.logger.warn(
          "[Bali] LocationsMap::Component was rendered without a Google Maps key, so nothing was " \
          "output. Set `Bali.google_maps.api_key` or the GOOGLE_MAPS_KEY environment variable: " \
          "see docs/guides/external-services.md."
        )
        false
      end

      private

      attr_reader :center_latitude, :center_longitude, :zoom, :clustered, :fit_to_locations,
                  :map_class, :options

      def component_options
        opts = prepend_class_name(options, BASE_CLASSES)
        opts = prepend_controller(opts, "locations-map")
        prepend_values(opts, "locations-map", controller_values)
      end

      # Read as the `static values` of index.js. The key is the one `google_maps_meta_tags` puts in
      # the <head>, written here too so a layout without that helper still loads the map.
      def controller_values
        {
          api_key: Bali.google_maps.api_key,
          enable_clustering: clustered,
          fit_to_locations: fit_to_locations,
          zoom: zoom,
          center_latitude: center_latitude,
          center_longitude: center_longitude
        }
      end

      def render_locations
        safe_join(locations)
      end

      def render_map
        tag.div(class: class_names(MAP_CLASSES, map_class), data: { locations_map_target: "map" })
      end
    end
  end
end
