# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Icon::LucideMapping do
  describe '.find' do
    it 'returns Lucide name for mapped Bali icon' do
      expect(described_class.find('edit')).to eq('pencil')
      expect(described_class.find('trash')).to eq('trash-2')
      expect(described_class.find('cog')).to eq('settings')
    end

    it 'returns nil for unmapped icons' do
      expect(described_class.find('visa')).to be_nil
      expect(described_class.find('nonexistent')).to be_nil
    end

    it 'accepts symbols' do
      expect(described_class.find(:edit)).to eq('pencil')
    end
  end

  describe '.mapped?' do
    it 'returns true for mapped icons' do
      expect(described_class.mapped?('user')).to be true
      expect(described_class.mapped?('check')).to be true
    end

    it 'returns false for unmapped icons' do
      expect(described_class.mapped?('visa')).to be false
      expect(described_class.mapped?('whatsapp')).to be false
    end
  end

  describe '.bali_names' do
    it 'returns all Bali icon names that have mappings' do
      names = described_class.bali_names

      expect(names).to include('edit', 'trash', 'user', 'check')
      expect(names).not_to include('visa', 'whatsapp')
    end
  end

  describe '.lucide_names' do
    it 'returns unique Lucide names used in mappings' do
      names = described_class.lucide_names

      expect(names).to include('pencil', 'trash-2', 'user', 'check')
      expect(names.uniq.size).to eq(names.size)
    end
  end

  describe 'MAPPING constant' do
    it 'is frozen' do
      expect(described_class::MAPPING).to be_frozen
    end

    it 'has string keys' do
      expect(described_class::MAPPING.keys).to all(be_a(String))
    end

    it 'has string values' do
      expect(described_class::MAPPING.values).to all(be_a(String))
    end
  end
end
