module Bali
  module LocationsMap
    module Card
      class Component < ApplicationViewComponent
        attr_reader :options

        def initialize(latitude: nil, longitude: nil, **options)
          @options = prepend_class_name(options, 'locations-map-component--card')
          @options = prepend_data_attribute(@options, :locations_map_target, :card)
          @options = prepend_data_attribute(@options, :latitude, latitude)
          @options = prepend_data_attribute(@options, :longitude, longitude)
        end

        def call
          tag.div(**options) { content }
        end
      end
    end
  end
end