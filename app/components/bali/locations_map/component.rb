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
        @center_latitude = center_latitude
        @center_longitude = center_longitude
        @zoom = zoom
        @clustered = clustered

        @options = prepend_class_name(options, 'locations-map-component')
        @options = prepend_controller(@options, 'locations-map')
        @options = setup_data_options(@options)
      end

      private

      def setup_data_options(opts)
        {
          'key' => ENV.fetch('GOOGLE_MAPS_KEY', ''),
          'enable-clustering-value' => @clustered,
          'zoom-value' => @zoom,
          'center-latitude-value' => @center_latitude,
          'center-longitude-value' => @center_longitude,
          'center-locale-value' => I18n.locale
        }.each do |attribute_name, attribute_value|
          attribute_name = "locations-map-#{attribute_name}"
          opts = prepend_data_attribute(opts, attribute_name, attribute_value)
        end

        opts
      end
    end
  end
end
