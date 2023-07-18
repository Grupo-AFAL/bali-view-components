# frozen_string_literal: true

module Bali
  module LocationsMap
    class Component < ApplicationViewComponent
      CENTER_LAT = 32.5036383
      CENTER_LNG = -117.0308968

      attr_reader :options

      renders_many :locations, Location::Component

      def initialize(
        center_latitude: CENTER_LAT, center_longitude: CENTER_LNG, zoom: 12, clustered: false,
        **options
      )
        @options = prepend_class_name(options, 'locations-map-component')
        @options = prepend_controller(@options, 'locations-map')
        @options = prepend_data_attribute(
          @options, 'locations-map-key', ENV.fetch('GOOGLE_MAPS_KEY', '')
        )
        @options = prepend_data_attribute(
          @options, 'locations-map-enable-clustering-value', clustered
        )
        @options = prepend_data_attribute(@options, 'locations-map-zoom-value', zoom)
        @options = prepend_data_attribute(
          @options, 'locations-map-center-latitude-value', center_latitude
        )
        @options = prepend_data_attribute(
          @options, 'locations-map-center-longitude-value', center_longitude
        )
      end
    end
  end
end
