# frozen_string_literal: true

module Bali
  module LocationsMap
    module Location
      class Component < ApplicationViewComponent
        attr_reader :latitude, :longitude, :label, :color, :border_color, :icon_url, :glyph_color,
                    :name

        renders_one :info_view

        def initialize(
          latitude:, longitude:, name: '', label: nil, color: nil, border_color: nil, icon_url: nil,
          glyph_color: nil
        )
          @name = name
          @latitude = latitude
          @longitude = longitude
          @label = label
          @color = color
          @border_color = border_color
          @icon_url = icon_url
          @glyph_color = glyph_color
        end

        def data_attributes
          {
            locations_map_target: 'location',
            info_view_id: info_view_id,
            name: name,
            lat: latitude,
            lng: longitude,
            marker_url: icon_url,
            marker_label: label,
            marker_color: color,
            marker_border_color: border_color,
            marker_glyph_color: glyph_color
          }.compact
        end

        private

        def unique_identifier
          @unique_identifier ||= "#{SecureRandom.uuid}-#{DateTime.now.strftime('%Q')}"
        end

        def info_view_id
          "map-location-info-view-template-#{unique_identifier}"
        end
      end
    end
  end
end
