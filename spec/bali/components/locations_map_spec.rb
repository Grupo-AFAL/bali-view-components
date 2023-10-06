# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::LocationsMap::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::LocationsMap::Component.new(**options) }

  context 'default' do
    it 'renders locations map component' do
      render_inline(component)

      expect(page).to have_css 'div.locations-map-component'
    end
  end

  context 'with custom location marker' do
    it 'renders locations map component' do
      render_inline(component) do |c|
        c.location(
          latitude: 10, longitude: 10, color: 'gray', border_color: 'black', glyph_color: 'black',
          label: 'label'
        )
      end

      expect(page).to have_css 'div.locations-map-component'
      expect(page).to have_css 'span[data-marker-label="label"]'
      expect(page).to have_css 'span[data-marker-color="gray"]'
      expect(page).to have_css 'span[data-marker-border-color="black"]'
      expect(page).to have_css 'span[data-marker-glyph-color="black"]'
    end
  end

  context 'with location without info view' do
    it 'renders locations map component' do
      render_inline(component) do |c|
        c.location(latitude: 10, longitude: 10)
      end

      expect(page).to have_css 'div.locations-map-component'
      expect(page).to have_css 'span[data-locations-map-target="location"]'
      expect(page).not_to have_css 'template', visible: false
    end
  end

  context 'with location with info view' do
    it 'renders locations map component' do
      render_inline(component) do |c|
        c.location(latitude: 10, longitude: 10) do |location|
          location.info_view do
            '<p>This is an info view</p>'.html_safe
          end
        end
      end

      expect(page).to have_css 'div.locations-map-component'
      expect(page).to have_css 'span[data-locations-map-target="location"]'
      expect(page).to have_css 'template', visible: false
    end
  end

  context 'with cards' do
    it 'renders locations map component' do
      render_inline(component) do |c|
        c.card(latitude: 10, longitude: 10) { '<p>Card</p>'.html_safe }
        c.location(latitude: 10, longitude: 10) do |location|
          location.info_view do
            '<p>This is an info view</p>'.html_safe
          end
        end
      end

      expect(page).to have_css 'div.locations-map-component'
      expect(page).to have_css 'div.locations-map-component--cards'
      expect(page).to have_css 'div.locations-map-component--locations'
      expect(page).to have_css 'div.locations-map-component--card'
      expect(page).to have_css 'p', text: 'Card'
      expect(page).to have_css 'span[data-locations-map-target="location"]'
      expect(page).to have_css 'template', visible: false
    end
  end
end
