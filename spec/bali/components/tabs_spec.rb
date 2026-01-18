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

    it 'renders correct ARIA attributes' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab 1', active: true) { 'Content 1' }
        c.with_tab(title: 'Tab 2') { 'Content 2' }
      end

      # Active tab
      expect(page).to have_css 'a[role="tab"][aria-selected="true"][tabindex="0"]'
      # Inactive tab
      expect(page).to have_css 'a[role="tab"][aria-selected="false"][tabindex="-1"]'
      # Tab panels
      expect(page).to have_css '[role="tabpanel"][aria-labelledby="tab-0"]'
      expect(page).to have_css '[role="tabpanel"][aria-labelledby="tab-1"]'
    end

    it 'sets up Stimulus controller' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '[data-controller="tabs"]'
    end
  end

  describe 'styles' do
    it 'renders border style by default' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs.tabs-border'
    end

    it 'renders default style with no extra classes' do
      render_inline(described_class.new(style: :default)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs'
      expect(page).not_to have_css '.tabs-border'
      expect(page).not_to have_css '.tabs-box'
      expect(page).not_to have_css '.tabs-lift'
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

    it 'handles invalid style gracefully' do
      render_inline(described_class.new(style: :invalid)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs'
    end
  end

  describe 'sizes' do
    it 'renders xs size' do
      render_inline(described_class.new(size: :xs)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs.tabs-xs'
    end

    it 'renders small size' do
      render_inline(described_class.new(size: :sm)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs.tabs-sm'
    end

    it 'renders medium size with no extra classes' do
      render_inline(described_class.new(size: :md)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs'
      expect(page).not_to have_css '.tabs-md'
    end

    it 'renders large size' do
      render_inline(described_class.new(size: :lg)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs.tabs-lg'
    end

    it 'renders xl size' do
      render_inline(described_class.new(size: :xl)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs.tabs-xl'
    end

    it 'handles invalid size gracefully' do
      render_inline(described_class.new(size: :invalid)) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs'
    end
  end

  describe 'with icons' do
    it 'renders tabs with icon' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', active: true, icon: 'alert') { '<p>Tab content</p>'.html_safe }
      end

      expect(page).to have_css 'span.icon-component svg'
    end

    it 'renders tab with icon but no title' do
      render_inline(described_class.new) do |c|
        c.with_tab(icon: 'settings', active: true) { 'Content' }
      end

      expect(page).to have_css 'a.tab span.icon-component'
      expect(page).to have_css 'a.tab span', text: ''
    end
  end

  describe 'with href (full page navigation)' do
    it 'renders tabs with href for full page navigation' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', href: '/')
      end

      expect(page).to have_css 'a.tab[href="/"]'
    end

    it 'does not include Stimulus data attributes when href is present' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', href: '/page')
      end

      expect(page).to have_css 'a.tab[href="/page"]'
      expect(page).not_to have_css 'a.tab[data-action]'
    end
  end

  describe 'with src (on-demand loading)' do
    it 'renders tabs with src for lazy loading' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', src: '/content', active: true)
      end

      expect(page).to have_css 'a.tab[data-tabs-src-param="/content"]'
    end

    it 'renders tabs with reload option' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', src: '/content', reload: true, active: true)
      end

      expect(page).to have_css 'a.tab[data-tabs-reload-param="true"]'
    end

    it 'defaults reload to false' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', src: '/content', active: true)
      end

      expect(page).to have_css 'a.tab[data-tabs-reload-param="false"]'
    end
  end

  describe 'options passthrough' do
    it 'passes custom class to container' do
      render_inline(described_class.new(class: 'custom-tabs')) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '.tabs-component.custom-tabs'
    end

    it 'passes data attributes to container' do
      render_inline(described_class.new(data: { testid: 'my-tabs' })) do |c|
        c.with_tab(title: 'Tab', active: true) { 'Content' }
      end

      expect(page).to have_css '[data-testid="my-tabs"]'
    end

    it 'passes custom options to tab content' do
      render_inline(described_class.new) do |c|
        c.with_tab(title: 'Tab', active: true, class: 'custom-panel') { 'Content' }
      end

      expect(page).to have_css '[role="tabpanel"].custom-panel'
    end
  end
end
