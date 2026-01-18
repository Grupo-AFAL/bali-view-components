# frozen_string_literal: true

module Bali
  module LocationsMap
    class Component < ApplicationViewComponent
      # Default center: Tijuana, Mexico (can be overridden via center_latitude/center_longitude)
      DEFAULT_CENTER_LAT = 32.5036383
      DEFAULT_CENTER_LNG = -117.0308968

      BASE_CLASSES = 'locations-map-component flex max-md:flex-col'
      MAP_CLASSES = 'location-map flex-1 h-[450px]'
      CARDS_WRAPPER_CLASSES = 'locations-map-component--cards flex-1 mr-3 max-md:mr-0'
      LOCATIONS_WRAPPER_CLASSES = 'locations-map-component--locations flex-1 ml-3 ' \
                                  'max-md:ml-0 max-md:mt-6'

      renders_many :cards, Card::Component
      renders_many :locations, Location::Component

      def initialize(
        center_latitude: DEFAULT_CENTER_LAT,
        center_longitude: DEFAULT_CENTER_LNG,
        zoom: 12,
        clustered: false,
        **options
      )
        @center_latitude = center_latitude
        @center_longitude = center_longitude
        @zoom = zoom
        @clustered = clustered
        @options = options
      end

      private

      attr_reader :center_latitude, :center_longitude, :zoom, :clustered, :options

      def component_options
        opts = prepend_class_name(options, BASE_CLASSES)
        opts = prepend_controller(opts, 'locations-map')
        prepend_values(opts, 'locations-map', controller_values)
      end

      def controller_values
        {
          api_key: ENV.fetch('GOOGLE_MAPS_KEY', nil),
          enable_clustering: clustered,
          zoom: zoom,
          center_latitude: center_latitude,
          center_longitude: center_longitude,
          center_locale: I18n.locale
        }
      end

      def render_locations
        safe_join(locations)
      end

      def render_map
        tag.div(class: MAP_CLASSES, data: { locations_map_target: 'map' })
      end
    end
  end
end
