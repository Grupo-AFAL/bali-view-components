# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tag::Component, type: :component do
  describe 'basic rendering' do
    it 'renders a badge with text' do
      render_inline(described_class.new(text: 'Hello'))

      expect(page).to have_css('div.badge', text: 'Hello')
    end

    it 'renders as a link when href is provided' do
      render_inline(described_class.new(text: 'Click me', href: '/path'))

      expect(page).to have_css('a.badge[href="/path"]', text: 'Click me')
    end
  end

  describe 'colors' do
    it 'applies DaisyUI color classes' do
      render_inline(described_class.new(text: 'Tag', color: :primary))

      expect(page).to have_css('div.badge.badge-primary')
    end

    it 'maps legacy Bulma colors to DaisyUI equivalents' do
      render_inline(described_class.new(text: 'Tag', color: :danger))

      expect(page).to have_css('div.badge.badge-error')
    end

    it 'maps black to neutral' do
      render_inline(described_class.new(text: 'Tag', color: :black))

      expect(page).to have_css('div.badge.badge-neutral')
    end
  end

  describe 'sizes' do
    it 'applies DaisyUI size classes' do
      render_inline(described_class.new(text: 'Tag', size: :lg))

      expect(page).to have_css('div.badge.badge-lg')
    end

    it 'maps legacy Bulma sizes to DaisyUI equivalents' do
      render_inline(described_class.new(text: 'Tag', size: :small))

      expect(page).to have_css('div.badge.badge-sm')
    end

    it 'supports all DaisyUI sizes' do
      %i[xs sm md lg xl].each do |size|
        render_inline(described_class.new(text: 'Tag', size: size))

        expect(page).to have_css("div.badge.badge-#{size}")
      end
    end
  end

  describe 'styles' do
    it 'applies outline style' do
      render_inline(described_class.new(text: 'Tag', style: :outline))

      expect(page).to have_css('div.badge.badge-outline')
    end

    it 'applies soft style' do
      render_inline(described_class.new(text: 'Tag', style: :soft))

      expect(page).to have_css('div.badge.badge-soft')
    end

    it 'applies dash style' do
      render_inline(described_class.new(text: 'Tag', style: :dash))

      expect(page).to have_css('div.badge.badge-dash')
    end

    it 'combines style with color' do
      render_inline(described_class.new(text: 'Tag', style: :outline, color: :primary))

      expect(page).to have_css('div.badge.badge-outline.badge-primary')
    end
  end

  describe 'legacy light parameter' do
    it 'applies outline style for backward compatibility' do
      allow(Rails.logger).to receive(:warn)

      render_inline(described_class.new(text: 'Tag', light: true))

      expect(page).to have_css('div.badge.badge-outline')
    end

    it 'emits deprecation warning' do
      expect(Rails.logger).to receive(:warn).with(/light.*deprecated.*style: :outline/)

      render_inline(described_class.new(text: 'Tag', light: true))
    end

    it 'style parameter takes precedence over light' do
      allow(Rails.logger).to receive(:warn)

      render_inline(described_class.new(text: 'Tag', light: true, style: :soft))

      expect(page).to have_css('div.badge.badge-soft')
      expect(page).not_to have_css('div.badge.badge-outline')
    end
  end

  describe 'custom color' do
    it 'applies custom background color with contrasting text' do
      render_inline(described_class.new(text: 'Tag', custom_color: '#ff0000'))

      expect(page).to have_css('div.badge[style*="background-color: #ff0000"]')
      expect(page).to have_css('div.badge[style*="color:"]')
    end
  end

  describe 'rounded' do
    it 'applies rounded-full class when rounded is true' do
      render_inline(described_class.new(text: 'Tag', rounded: true))

      expect(page).to have_css('div.badge.rounded-full')
    end

    it 'does not apply rounded-full class when rounded is false' do
      render_inline(described_class.new(text: 'Tag', rounded: false))

      expect(page).not_to have_css('div.badge.rounded-full')
    end
  end

  describe 'HTML attribute passthrough' do
    it 'passes additional attributes to the element' do
      render_inline(described_class.new(text: 'Tag', data: { testid: 'my-tag' }))

      expect(page).to have_css('div.badge[data-testid="my-tag"]')
    end

    it 'merges custom classes with component classes' do
      render_inline(described_class.new(text: 'Tag', class: 'my-custom-class'))

      expect(page).to have_css('div.badge.my-custom-class')
    end
  end
end
