# External Services Configuration

Some Bali components require external API keys or services to function. This guide explains how to configure them.

---

## LocationsMap Component

The `Bali::LocationsMap::Component` displays an interactive Google Map with location markers.

### Requirements

- **Google Maps JavaScript API** key
- Billing enabled on your Google Cloud project (required by Google, even for free tier usage)

### Setup

#### 1. Create a Google Cloud API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select or create a project
3. Navigate to **APIs & Services → Library**
4. Search for and enable **Maps JavaScript API**
5. Go to **APIs & Services → Credentials**
6. Click **Create Credentials → API Key**
7. (Recommended) Restrict the key:
   - **Application restrictions**: Set to "Websites" and add your domains
   - **API restrictions**: Select "Restrict key" and choose "Maps JavaScript API"

#### 2. Configure the Key

Bali reads the key from `Bali.google_maps.api_key`, so it can come from wherever the
application already keeps its credentials:

```ruby
# config/initializers/bali.rb
Bali.config do |config|
  config.google_maps.api_key = Rails.application.credentials.dig(:google, :maps_key)
  # Optional: a map ID registered in Google Cloud, for its map style.
  config.google_maps.map_id = Rails.application.credentials.dig(:google, :map_id)
end
```

With no `api_key` it falls back to the `GOOGLE_MAPS_KEY` environment
variable, which is all v2 ever read — an application that already exports it
needs no initializer:

```bash
# .env (add to .gitignore!) or environment configuration
GOOGLE_MAPS_KEY=AIzaSy...your_key_here
```

For Rails applications using `dotenv`:

```ruby
# Gemfile
gem 'dotenv-rails', groups: [:development, :test]
```

`Bali.google_maps_key` still reads and sets the key, with a deprecation warning, and
goes in 4.0.

#### 3. Hand It to the Page

Every Google map on the page — LocationsMap, `coordinates_polygon_group`, and the
`autocomplete-address`, `geocoder-maps` and `drawing-maps` controllers — reads its key and
map ID from two `<meta>` tags in the layout's `<head>`, and its language from the
`<html lang>`:

```erb
<html lang="<%= I18n.locale %>">
  <head>
    <%= google_maps_meta_tags %>
```

- **Language.** The Maps API loads once per page, so every map on it is in the language
  of the `<html>`, whatever `lang` an element closer to the map declares. The tag is
  passed whole: `es-MX` gets Google's Latin American wording. With no `lang`, English.
- **Map ID.** Without one, each map makes one up, which is enough for its markers but
  carries no Cloud style.
- **A key on the element wins** over the page's: `data-locations-map-api-key-value`,
  `data-drawing-maps-key`, `data-geocoder-maps-key` and
  `data-autocomplete-address-api-key-value`. LocationsMap and `coordinates_polygon_group`
  still write the key on their element, so they load without the helper; the map ID
  reaches them only through it.

A controller of the app's own reads the same configuration:

```js
import { googleMapsConfig, loadGoogleMapsApi } from 'bali-view-components'

const { key, language, mapId } = googleMapsConfig()
const maps = await loadGoogleMapsApi({ key, language })
new maps.Map(element, { center, zoom: 15, mapId })
```

#### 4. Use the Component

```erb
<%= render Bali::LocationsMap::Component.new(
  center_latitude: 40.7128,
  center_longitude: -74.0060,
  zoom: 12
) do |c| %>
  <% c.with_location(latitude: 40.7128, longitude: -74.0060, name: "New York") %>
<% end %>
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `center_latitude` | Float | 32.5036 | Initial map center latitude |
| `center_longitude` | Float | -117.0308 | Initial map center longitude |
| `zoom` | Integer | 12 | Initial zoom level (1-20) |
| `clustered` | Boolean | false | Enable marker clustering |

### Location Markers

Add markers with `with_location`:

```erb
<% c.with_location(
  latitude: 40.7128,
  longitude: -74.0060,
  name: "Location Name",
  color: "#ff0000",           # Marker fill color
  border_color: "#cc0000",    # Marker border color
  glyph_color: "#ffffff",     # Marker label color
  label: "A",                 # Marker label text
  icon_url: "/custom-pin.png" # Custom marker image (overrides colors)
) do |location|
  # Optional: Add an info window
  location.with_info_view do %>
    <div class="p-2">
      <h3>Location Details</h3>
      <p>Custom HTML content here</p>
    </div>
  <% end %>
<% end %>
```

### Cards (Optional)

Display clickable cards alongside the map that highlight when clicking markers:

```erb
<%= render Bali::LocationsMap::Component.new do |c| %>
  <% locations.each do |loc| %>
    <% c.with_card(latitude: loc.lat, longitude: loc.lng) do %>
      <h3><%= loc.name %></h3>
      <p><%= loc.address %></p>
    <% end %>

    <% c.with_location(latitude: loc.lat, longitude: loc.lng, name: loc.name) %>
  <% end %>
<% end %>
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| "For development purposes only" watermark | API key missing or invalid. Check `Bali.google_maps.api_key` resolves to it and `google_maps_meta_tags` is in the `<head>`. |
| Map controls in the wrong language | The map follows the `<html lang>`. Set it on the layout's `<html>`. |
| `ApiProjectMapError` in console | Maps JavaScript API not enabled. Enable it in Google Cloud Console. |
| `RefererNotAllowedMapError` | Domain not allowed. Add your domain to key restrictions. |
| Map doesn't load | Check browser console for errors. Verify billing is enabled. |

### Security Notes

- **Never commit API keys** to version control. Use environment variables.
- **Restrict your keys** to specific domains and APIs in production.
- **Monitor usage** in Google Cloud Console to detect abuse.

---

## AutocompleteAddress (Form Field)

The address autocomplete form field also requires Google Maps APIs.

### Requirements

- **Maps JavaScript API**, which loads the search box.
- **Places API (New)**, for the suggestions and the place picked. It is listed apart
  from the legacy **Places API**, which the field no longer uses.

### Setup

The field is wired by hand in the host's markup, and takes its key from
`google_maps_meta_tags` like every other map ([Hand It to the Page](#3-hand-it-to-the-page)).
A `data-autocomplete-address-api-key-value` on the element wins over it.

Enable both:

1. Go to **APIs & Services → Library**
2. Enable **Maps JavaScript API** and **Places API (New)**
3. Add both to your API key restrictions

---

## CoordinatesPolygon (Form Field)

The polygon drawing field for defining geographic boundaries.

### Requirements

Same as LocationsMap - requires **Maps JavaScript API**.

### Setup

Uses the same configuration, `Bali.google_maps`, and loads in the language of the
`<html lang>`.
