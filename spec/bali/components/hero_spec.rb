# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Hero::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Hero::Component.new(**options) }

  describe 'basic rendering' do
    it 'renders hero component with title and subtitle' do
      render_inline(component) do |c|
        c.with_title('Titulo')
        c.with_subtitle('Subtitulo')
      end

      expect(page).to have_css 'div.hero'
      expect(page).to have_css 'div.hero-content'
      expect(page).to have_css 'h1.text-5xl.font-bold', text: 'Titulo'
      expect(page).to have_css 'p.py-4', text: 'Subtitulo'
    end

    it 'renders with default background color' do
      render_inline(component)

      expect(page).to have_css 'div.hero.bg-base-200'
    end
  end

  describe 'sizes' do
    it 'renders small size' do
      render_inline(described_class.new(size: :sm))
      expect(page).to have_css 'div.hero.min-h-48'
    end

    it 'renders medium size' do
      render_inline(described_class.new(size: :md))
      expect(page).to have_css 'div.hero.min-h-80'
    end

    it 'renders large size' do
      render_inline(described_class.new(size: :lg))
      expect(page).to have_css 'div.hero.min-h-screen'
    end
  end

  describe 'colors' do
    it 'renders primary color' do
      render_inline(described_class.new(color: :primary))
      expect(page).to have_css 'div.hero.bg-primary.text-primary-content'
    end

    it 'renders secondary color' do
      render_inline(described_class.new(color: :secondary))
      expect(page).to have_css 'div.hero.bg-secondary.text-secondary-content'
    end

    it 'renders accent color' do
      render_inline(described_class.new(color: :accent))
      expect(page).to have_css 'div.hero.bg-accent.text-accent-content'
    end

    it 'renders neutral color' do
      render_inline(described_class.new(color: :neutral))
      expect(page).to have_css 'div.hero.bg-neutral.text-neutral-content'
    end
  end

  describe 'centered option' do
    it 'centers content by default' do
      render_inline(described_class.new)
      expect(page).to have_css 'div.hero-content.text-center'
    end

    it 'does not center content when disabled' do
      render_inline(described_class.new(centered: false))
      expect(page).to have_css 'div.hero-content'
      expect(page).not_to have_css 'div.hero-content.text-center'
    end
  end

  describe 'custom classes' do
    it 'accepts custom classes' do
      render_inline(described_class.new(class: 'custom-class'))
      expect(page).to have_css 'div.hero.custom-class'
    end
  end
end
