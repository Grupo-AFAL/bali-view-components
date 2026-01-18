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

#### 2. Configure the Environment Variable

Add the key to your environment:

```bash
# .env or environment configuration
GOOGLE_MAPS_KEY=AIzaSy...your_key_here
```

For Rails applications using `dotenv`:

```ruby
# Gemfile
gem 'dotenv-rails', groups: [:development, :test]
```

```bash
# .env (add to .gitignore!)
GOOGLE_MAPS_KEY=AIzaSy...your_key_here
```

#### 3. Use the Component

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
| "For development purposes only" watermark | API key missing or invalid. Check `GOOGLE_MAPS_KEY` is set. |
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

- **Places API** (for autocomplete suggestions)
- **Geocoding API** (for address details)

### Setup

Use the same `GOOGLE_MAPS_KEY` environment variable. Ensure both APIs are enabled:

1. Go to **APIs & Services → Library**
2. Enable **Places API**
3. Enable **Geocoding API**
4. Add both to your API key restrictions

---

## CoordinatesPolygon (Form Field)

The polygon drawing field for defining geographic boundaries.

### Requirements

Same as LocationsMap - requires **Maps JavaScript API**.

### Setup

Uses the same `GOOGLE_MAPS_KEY` environment variable.
