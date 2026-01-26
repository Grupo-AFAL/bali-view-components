# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::LocationsMap::Component, type: :component do
  let(:options) { {} }
  let(:component) { described_class.new(**options) }

  describe 'constants' do
    it 'has frozen BASE_CLASSES' do
      expect(described_class::BASE_CLASSES).to be_frozen
    end

    it 'has frozen MAP_CLASSES' do
      expect(described_class::MAP_CLASSES).to be_frozen
    end

    it 'defines default center coordinates' do
      expect(described_class::DEFAULT_CENTER_LAT).to eq(32.5036383)
      expect(described_class::DEFAULT_CENTER_LNG).to eq(-117.0308968)
    end
  end

  describe 'default rendering' do
    it 'renders with base classes' do
      render_inline(component)

      expect(page).to have_css 'div.locations-map-component'
      expect(page).to have_css 'div.flex'
    end

    it 'renders the map target div' do
      render_inline(component)

      expect(page).to have_css 'div.location-map[data-locations-map-target="map"]'
    end

    it 'includes Stimulus controller data attributes' do
      render_inline(component)

      expect(page).to have_css '[data-controller="locations-map"]'
    end

    it 'passes default center values to controller' do
      render_inline(component)

      expect(page).to have_css "[data-locations-map-center-latitude-value='32.5036383']"
      expect(page).to have_css "[data-locations-map-center-longitude-value='-117.0308968']"
    end
  end

  describe 'custom center coordinates' do
    let(:component) { described_class.new(center_latitude: 40.7128, center_longitude: -74.0060) }

    it 'uses custom center coordinates' do
      render_inline(component)

      expect(page).to have_css "[data-locations-map-center-latitude-value='40.7128']"
      expect(page).to have_css "[data-locations-map-center-longitude-value='-74.006']"
    end
  end

  describe 'zoom parameter' do
    let(:component) { described_class.new(zoom: 15) }

    it 'passes zoom value to controller' do
      render_inline(component)

      expect(page).to have_css "[data-locations-map-zoom-value='15']"
    end
  end

  describe 'clustered parameter' do
    let(:component) { described_class.new(clustered: true) }

    it 'passes clustering value to controller' do
      render_inline(component)

      expect(page).to have_css '[data-locations-map-enable-clustering-value="true"]'
    end
  end

  describe 'with custom location marker' do
    it 'renders marker data attributes' do
      render_inline(component) do |c|
        c.with_location(
          latitude: 10, longitude: 10, color: 'gray', border_color: 'black',
          glyph_color: 'black', label: 'label'
        )
      end

      expect(page).to have_css 'span[data-marker-label="label"]'
      expect(page).to have_css 'span[data-marker-color="gray"]'
      expect(page).to have_css 'span[data-marker-border-color="black"]'
      expect(page).to have_css 'span[data-marker-glyph-color="black"]'
    end

    it 'renders location with icon URL' do
      render_inline(component) do |c|
        c.with_location(
          latitude: 10, longitude: 10,
          icon_url: 'https://example.com/marker.png'
        )
      end

      expect(page).to have_css 'span[data-marker-url="https://example.com/marker.png"]'
    end
  end

  describe 'with location without info view' do
    it 'does not render template element' do
      render_inline(component) do |c|
        c.with_location(latitude: 10, longitude: 10)
      end

      expect(page).to have_css 'span[data-locations-map-target="location"]'
      expect(page).not_to have_css 'template', visible: false
    end
  end

  describe 'with location with info view' do
    it 'renders template element with info view content' do
      render_inline(component) do |c|
        c.with_location(latitude: 10, longitude: 10) do |location|
          location.with_info_view { 'Info content' }
        end
      end

      expect(page).to have_css 'span[data-locations-map-target="location"]'
      expect(page).to have_css 'template', visible: false
    end
  end

  describe 'with cards' do
    it 'renders cards and locations layout' do
      render_inline(component) do |c|
        c.with_card(latitude: 10, longitude: 10) { 'Card content' }
        c.with_location(latitude: 10, longitude: 10)
      end

      expect(page).to have_css 'div.locations-map-component--cards'
      expect(page).to have_css 'div.locations-map-component--locations'
      expect(page).to have_css 'div.locations-map-component--card'
    end

    it 'renders card with DaisyUI classes' do
      render_inline(component) do |c|
        c.with_card(latitude: 10, longitude: 10) { 'Card' }
        c.with_location(latitude: 10, longitude: 10)
      end

      expect(page).to have_css 'div.card'
      expect(page).to have_css 'div.card-border'
      expect(page).to have_css 'div.bg-base-100'
    end

    it 'passes card data attributes for map interaction' do
      render_inline(component) do |c|
        c.with_card(latitude: 10.5, longitude: 20.5) { 'Card' }
        c.with_location(latitude: 10.5, longitude: 20.5)
      end

      expect(page).to have_css 'div[data-locations-map-target="card"]'
      expect(page).to have_css 'div[data-latitude="10.5"]'
      expect(page).to have_css 'div[data-longitude="20.5"]'
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(class: 'custom-class'))

      expect(page).to have_css 'div.locations-map-component.custom-class'
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(data: { testid: 'map-component' }))

      expect(page).to have_css '[data-testid="map-component"]'
    end
  end
end
