# frozen_string_literal: true

module Bali
  module LocationsMap
    class Component < ApplicationViewComponent
      CENTER_LAT = 32.5036383
      CENTER_LNG = -117.0308968

      attr_reader :options

      renders_many :cards,  Card::Component
      renders_many :locations, Location::Component

      def initialize(
        center_latitude: CENTER_LAT, center_longitude: CENTER_LNG, zoom: 12, clustered: false,
        **options
      )
        @center_latitude = center_latitude
        @center_longitude = center_longitude
        @zoom = zoom
        @clustered = clustered

        @options = prepend_class_name(options, 'locations-map-component')
        @options = prepend_controller(@options, 'locations-map')
        @options = prepend_values(@options, 'locations-map', controller_values)
      end

      private

      def controller_values
        {
          api_key: ENV.fetch('GOOGLE_MAPS_KEY', ''),
          enable_clustering: @clustered,
          zoom: @zoom,
          center_latitude: @center_latitude,
          center_longitude: @center_longitude,
          center_locale: I18n.locale
        }
      end
    end
  end
end
