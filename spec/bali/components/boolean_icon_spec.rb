# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::BooleanIcon::Component, type: :component do
  describe 'with true value' do
    it 'renders success styling' do
      render_inline(described_class.new(value: true))

      expect(page).to have_css('div.boolean-icon-component.text-success')
    end

    it 'renders check-circle icon' do
      render_inline(described_class.new(value: true))

      # Verify icon is rendered (SVG with path)
      expect(page).to have_css('.icon-component svg')
    end
  end

  describe 'with false value' do
    it 'renders error styling' do
      render_inline(described_class.new(value: false))

      expect(page).to have_css('div.boolean-icon-component.text-error')
    end

    it 'renders times-circle icon' do
      render_inline(described_class.new(value: false))

      # Verify icon is rendered (SVG with path)
      expect(page).to have_css('.icon-component svg')
    end
  end

  describe 'with nil value' do
    it 'treats nil as false' do
      render_inline(described_class.new(value: nil))

      expect(page).to have_css('div.boolean-icon-component.text-error')
      expect(page).to have_css('.icon-component svg')
    end
  end

  describe 'options passthrough' do
    it 'merges custom classes' do
      render_inline(described_class.new(value: true, class: 'custom-class'))

      expect(page).to have_css('div.boolean-icon-component.custom-class')
    end

    it 'passes data attributes' do
      render_inline(described_class.new(value: true, data: { testid: 'boolean-icon' }))

      expect(page).to have_css('[data-testid="boolean-icon"]')
    end
  end
end
