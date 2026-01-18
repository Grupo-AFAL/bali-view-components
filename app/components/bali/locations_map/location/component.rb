# frozen_string_literal: true

module Bali
  module LocationsMap
    module Location
      class Component < ApplicationViewComponent
        renders_one :info_view

        # rubocop:disable Metrics/ParameterLists
        def initialize(
          latitude:,
          longitude:,
          name: '',
          label: nil,
          color: nil,
          border_color: nil,
          icon_url: nil,
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
        # rubocop:enable Metrics/ParameterLists

        private

        attr_reader :name, :latitude, :longitude, :label, :color, :border_color, :icon_url,
                    :glyph_color

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

        def info_view_id
          @info_view_id ||= "map-location-info-view-template-#{SecureRandom.uuid}"
        end
      end
    end
  end
end
