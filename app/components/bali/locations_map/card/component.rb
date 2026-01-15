# frozen_string_literal: true

module Bali
  module LocationsMap
    module Card
      class Component < ApplicationViewComponent
        attr_reader :options

        CARD_CLASSES = 'locations-map-component--card bg-base-100 rounded-box p-5 shadow ' \
                       '[&.is-selected]:bg-info [&.is-selected]:text-info-content'

        def initialize(latitude: nil, longitude: nil, **options)
          @options = prepend_class_name(options, CARD_CLASSES)
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
