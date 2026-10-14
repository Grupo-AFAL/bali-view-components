# frozen_string_literal: true

module Bali
  # Exposed to host app views (see the engine initializer), for the layout's `<head>`:
  #
  #   <%= google_maps_meta_tags %>
  #
  # Hands `Bali.google_maps` to every map on the page: `googleMapsConfig()` in
  # app/assets/javascripts/bali/utils/google-maps-loader.js reads these two names.
  module GoogleMapsHelper
    KEY_META = "bali-google-maps-key"
    MAP_ID_META = "bali-google-maps-map-id"

    def google_maps_meta_tags
      config = Bali.google_maps
      tags = []
      tags << tag.meta(name: KEY_META, content: config.api_key) if config.api_key
      tags << tag.meta(name: MAP_ID_META, content: config.map_id) if config.map_id

      safe_join(tags, "\n")
    end
  end
end
