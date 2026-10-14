# frozen_string_literal: true

module Bali
  # What every Google map in the app loads with, as `Bali.google_maps`. `google_maps_meta_tags`
  # (Bali::GoogleMapsHelper) writes it into the layout's `<head>`, where the four map
  # controllers read it.
  #
  #   Bali.google_maps.api_key = Rails.application.credentials.dig(:google, :maps_key)
  #   Bali.google_maps.map_id = Rails.application.credentials.dig(:google, :map_id)
  class GoogleMaps
    attr_writer :api_key, :map_id

    # Falls back to the `GOOGLE_MAPS_KEY` environment variable, resolved per call: an initializer
    # runs before an application's own credential loading in more setups than not, and a value
    # frozen at boot would be empty forever in every one of them.
    def api_key
      @api_key.presence || ENV["GOOGLE_MAPS_KEY"].presence
    end

    # A map ID registered in Google Cloud. Without one, each map makes one up, which is enough for
    # an AdvancedMarkerElement but carries no Cloud style.
    def map_id
      @map_id.presence
    end
  end
end
