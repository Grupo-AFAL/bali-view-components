# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tabs::Component, type: :component do
  describe 'basic rendering' do
    it 'renders tabs with content' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab 1', active: true) { '<p>Tab 1 content</p>'.html_safe }
        c.with_tab(title: 'Tab 2') { '<p>Tab 2 content</p>'.html_safe }
      end

      expect(page).to have_css '.tabs-component'
      expect(page).to have_css 'a.tab.tab-active', text: 'Tab 1'
      expect(page).to have_css 'a.tab', text: 'Tab 2'
      expect(page).to have_css 'p', text: 'Tab 1 content'
      expect(page).to have_css '.hidden p', text: 'Tab 2 content'
    end

    it 'renders tabs with tablist role for accessibility' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab 1', active: true) { 'Content' }
      end

      expect(page).to have_css '[role="tablist"]'
      expect(page).to have_css 'a[role="tab"]'
    end
  end

  describe 'styles' do
    it 'renders border style by default' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs.tabs-border'
    end

    it 'renders box style' do
      render_inline(described_class.new(style: :box)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs.tabs-box'
    end

    it 'renders lift style' do
      render_inline(described_class.new(style: :lift)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs.tabs-lift'
    end
  end

  describe 'sizes' do
    it 'renders small size' do
      render_inline(described_class.new(size: :sm)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs.tabs-sm'
    end

    it 'renders large size' do
      render_inline(described_class.new(size: :lg)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs.tabs-lg'
    end
  end

  describe 'with icons' do
    it 'renders tabs with icon' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', active: true, icon: 'alert') { '<p>Tab content</p>'.html_safe }
      end

      expect(page).to have_css 'span.icon-component svg'
    end
  end

  describe 'with href' do
    it 'renders tabs with href for full page navigation' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', href: '/')
      end

      expect(page).to have_css 'a.tab[href="/"]'
    end
  end
end
