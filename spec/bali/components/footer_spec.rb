# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Footer::Component, type: :component do
  describe 'rendering' do
    it 'renders a footer element' do
      render_inline(described_class.new)

      expect(page).to have_css('footer.footer-component')
    end

    it 'applies neutral color by default' do
      render_inline(described_class.new)

      expect(page).to have_css('footer.bg-neutral.text-neutral-content')
    end

    it 'applies custom color' do
      render_inline(described_class.new(color: :primary))

      expect(page).to have_css('footer.bg-primary.text-primary-content')
    end

    it 'centers content when center is true' do
      render_inline(described_class.new(center: true))

      expect(page).to have_css('.footer-center')
    end
  end

  describe 'brand slot' do
    it 'renders brand with name and description' do
      render_inline(described_class.new) do |footer|
        footer.with_brand(name: 'ACME', description: 'Building the future')
      end

      expect(page).to have_css('aside h3', text: 'ACME')
      expect(page).to have_css('aside p', text: 'Building the future')
    end

    it 'renders brand with custom block' do
      render_inline(described_class.new) do |footer|
        footer.with_brand { 'Custom brand content' }
      end

      expect(page).to have_css('aside', text: 'Custom brand content')
    end
  end

  describe 'sections slot' do
    it 'renders section with title' do
      render_inline(described_class.new) do |footer|
        footer.with_section(title: 'Company') do |section|
          section.with_link(name: 'About', href: '/about')
        end
      end

      expect(page).to have_css('.footer-title', text: 'Company')
    end

    it 'renders section links' do
      render_inline(described_class.new) do |footer|
        footer.with_section(title: 'Links') do |section|
          section.with_link(name: 'Home', href: '/')
          section.with_link(name: 'About', href: '/about')
        end
      end

      expect(page).to have_css('a.link', text: 'Home')
      expect(page).to have_css('a.link', text: 'About')
      expect(page).to have_link('Home', href: '/')
    end

    it 'renders multiple sections' do
      render_inline(described_class.new) do |footer|
        footer.with_section(title: 'Product') do |section|
          section.with_link(name: 'Features', href: '#')
        end
        footer.with_section(title: 'Company') do |section|
          section.with_link(name: 'About', href: '#')
        end
      end

      expect(page).to have_css('.footer-title', text: 'Product')
      expect(page).to have_css('.footer-title', text: 'Company')
    end
  end

  describe 'bottom slot' do
    it 'renders bottom content' do
      render_inline(described_class.new) do |footer|
        footer.with_bottom { 'Copyright 2024' }
      end

      expect(page).to have_css('div.border-t', text: 'Copyright 2024')
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(class: 'custom-footer'))

      expect(page).to have_css('footer.footer-component.custom-footer')
    end

    it 'accepts id attribute' do
      render_inline(described_class.new(id: 'main-footer'))

      expect(page).to have_css('#main-footer')
    end
  end
end
