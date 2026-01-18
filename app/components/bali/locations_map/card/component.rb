# frozen_string_literal: true

module Bali
  module LocationsMap
    module Card
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'locations-map-component--card card card-border bg-base-100 p-5 shadow-sm ' \
                       '[&.is-selected]:bg-info [&.is-selected]:text-info-content'

        def initialize(latitude: nil, longitude: nil, **options)
          @latitude = latitude
          @longitude = longitude
          @options = options
        end

        def call
          tag.div(**component_options) { content }
        end

        private

        attr_reader :latitude, :longitude, :options

        def component_options
          opts = prepend_class_name(options, BASE_CLASSES)
          opts = prepend_data_attribute(opts, :locations_map_target, :card)
          opts = prepend_data_attribute(opts, :latitude, latitude)
          prepend_data_attribute(opts, :longitude, longitude)
        end
      end
    end
  end
end
