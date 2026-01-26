# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Icon::KeptIcons do
  describe '.exists?' do
    it 'returns true for brand payment icons' do
      expect(described_class.exists?('visa')).to be true
      expect(described_class.exists?('mastercard')).to be true
      expect(described_class.exists?('american-express')).to be true
    end

    it 'returns true for brand social icons' do
      expect(described_class.exists?('whatsapp')).to be true
      expect(described_class.exists?('facebook')).to be true
      expect(described_class.exists?('youtube')).to be true
    end

    it 'returns true for regional icons' do
      expect(described_class.exists?('mexico-flag')).to be true
      expect(described_class.exists?('us-flag')).to be true
    end

    it 'returns true for custom domain icons' do
      expect(described_class.exists?('recipe-book')).to be true
      expect(described_class.exists?('diagnose')).to be true
    end

    it 'returns false for icons not in kept set' do
      expect(described_class.exists?('user')).to be false
      expect(described_class.exists?('edit')).to be false
    end

    it 'accepts symbols' do
      expect(described_class.exists?(:visa)).to be true
    end
  end

  describe '.find' do
    it 'returns SVG markup for kept icons' do
      svg = described_class.find('visa')

      expect(svg).to include('<svg')
      expect(svg).to include('</svg>')
    end

    it 'raises error for non-kept icons' do
      expect do
        described_class.find('user')
      end.to raise_error(Bali::Icon::Options::IconNotAvailable)
    end
  end

  describe '.brand?' do
    it 'returns true for brand icons' do
      expect(described_class.brand?('visa')).to be true
      expect(described_class.brand?('whatsapp')).to be true
    end

    it 'returns false for non-brand icons' do
      expect(described_class.brand?('mexico-flag')).to be false
      expect(described_class.brand?('recipe-book')).to be false
    end
  end

  describe '.regional?' do
    it 'returns true for regional icons' do
      expect(described_class.regional?('mexico-flag')).to be true
      expect(described_class.regional?('us-flag')).to be true
    end

    it 'returns false for non-regional icons' do
      expect(described_class.regional?('visa')).to be false
    end
  end

  describe '.custom?' do
    it 'returns true for custom domain icons' do
      expect(described_class.custom?('recipe-book')).to be true
      expect(described_class.custom?('diagnose')).to be true
    end

    it 'returns false for non-custom icons' do
      expect(described_class.custom?('visa')).to be false
    end
  end

  describe 'constants' do
    it 'has frozen BRAND_PAYMENT' do
      expect(described_class::BRAND_PAYMENT).to be_frozen
    end

    it 'has frozen BRAND_SOCIAL' do
      expect(described_class::BRAND_SOCIAL).to be_frozen
    end

    it 'has frozen REGIONAL' do
      expect(described_class::REGIONAL).to be_frozen
    end

    it 'has frozen CUSTOM' do
      expect(described_class::CUSTOM).to be_frozen
    end

    it 'has frozen ALL containing all categories' do
      expect(described_class::ALL).to be_frozen
      expect(described_class::ALL).to include(*described_class::BRAND_PAYMENT)
      expect(described_class::ALL).to include(*described_class::BRAND_SOCIAL)
      expect(described_class::ALL).to include(*described_class::REGIONAL)
      expect(described_class::ALL).to include(*described_class::CUSTOM)
    end
  end
end
