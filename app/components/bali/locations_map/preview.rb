# frozen_string_literal: true

module Bali
  module LocationsMap
    class Preview < ApplicationViewComponentPreview
      LOCATIONS = [
        { latitude: 32.52535328002182, longitude: -117.01662677673296 },
        { latitude: 32.528469988815075, longitude: -117.0197954175343, color: 'green' },
        { latitude: 32.53146597286308, longitude: -117.02884042070805, color: '#f98f00',
          glyph_color: '#feddae', border_color: '#ea6200' },
        { latitude: 32.52900375149942, longitude: -117.0356861180097, color: '#f98f00',
          glyph_color: 'white', border_color: '#ea6200', label: 1 },
        { latitude: 32.52284404972829, longitude: -117.0330700546029,
          icon_url: "https://maps.google.com/mapfiles/kml/paddle/blu-blank.png" }
      ].freeze

      # @param zoom number
      # @param clustered [Boolean]
      def default(zoom: 12, clustered: false)
        render Bali::LocationsMap::Component.new(zoom: zoom, clustered: clustered) do |c|
          LOCATIONS.each do |location_attrs|
            c.location(**location_attrs)
          end

          c.location(latitude: 32.516284591574724, longitude: -117.0129754500983) do |location|
            location.info_view { '<p>This is an info view</p>'.html_safe }
          end
        end
      end

      def with_card(zoom: 12, clustered: false)
        render Bali::LocationsMap::Component.new(zoom: zoom, clustered: clustered) do |c|
          c.card(latitude: 32.516284591574724, longitude: -117.0129754500983) do
            '<p>This is a card</p>'.html_safe
          end

          LOCATIONS.each do |location_attrs|
            c.location(**location_attrs)
          end

          c.location(latitude: 32.516284591574724, longitude: -117.0129754500983) do |location|
            location.info_view { '<p>This is an info view</p>'.html_safe }
          end
        end
      end
    end
  end
end
