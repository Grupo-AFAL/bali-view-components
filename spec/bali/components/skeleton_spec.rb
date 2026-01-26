# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Skeleton::Component, type: :component do
  describe 'basic rendering' do
    it 'renders text variant by default' do
      render_inline(described_class.new)

      expect(page).to have_css('.skeleton')
    end

    it 'renders paragraph variant' do
      render_inline(described_class.new(variant: :paragraph, lines: 3))

      expect(page).to have_css('.skeleton', count: 3)
    end

    it 'renders card variant' do
      render_inline(described_class.new(variant: :card))

      expect(page).to have_css('.skeleton')
    end

    it 'renders avatar variant' do
      render_inline(described_class.new(variant: :avatar))

      expect(page).to have_css('.skeleton.rounded-full')
    end

    it 'renders button variant' do
      render_inline(described_class.new(variant: :button))

      expect(page).to have_css('.skeleton')
    end

    it 'renders modal variant' do
      render_inline(described_class.new(variant: :modal))

      expect(page).to have_css('.skeleton', minimum: 3)
    end

    it 'renders list variant' do
      render_inline(described_class.new(variant: :list, lines: 4))

      expect(page).to have_css('.skeleton', minimum: 4)
    end
  end

  describe 'sizes' do
    it 'renders xs size for avatar' do
      render_inline(described_class.new(variant: :avatar, size: :xs))

      expect(page).to have_css('.skeleton.w-8.h-8')
    end

    it 'renders sm size for avatar' do
      render_inline(described_class.new(variant: :avatar, size: :sm))

      expect(page).to have_css('.skeleton.w-10.h-10')
    end

    it 'renders md size for avatar' do
      render_inline(described_class.new(variant: :avatar, size: :md))

      expect(page).to have_css('.skeleton.w-12.h-12')
    end

    it 'renders lg size for avatar' do
      render_inline(described_class.new(variant: :avatar, size: :lg))

      expect(page).to have_css('.skeleton.w-16.h-16')
    end
  end

  describe 'custom options' do
    it 'accepts custom classes' do
      render_inline(described_class.new(class: 'my-custom-class'))

      expect(page).to have_css('.skeleton.my-custom-class')
    end
  end
end
