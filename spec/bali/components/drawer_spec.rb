# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Drawer::Component, type: :component do
  let(:component) { Bali::Drawer::Component.new(**@options) }

  before { @options = {} }

  describe 'basic rendering' do
    it 'renders drawer component' do
      render_inline(component)

      expect(page).to have_css 'div.drawer-component'
    end

    it 'renders drawer-open class when active' do
      @options.merge!(active: true)
      render_inline(component)

      expect(page).to have_css 'div.drawer-component.drawer-open'
    end

    it 'renders with custom content' do
      render_inline(component) do
        '<p>Hello World!</p>'.html_safe
      end

      expect(page).to have_css 'p', text: 'Hello World!'
    end
  end

  describe 'sizes' do
    it 'renders narrow size' do
      @options.merge!(size: :narrow)
      render_inline(component)

      expect(page).to have_css '.drawer-panel.max-w-sm'
    end

    it 'renders medium size by default' do
      render_inline(component)

      expect(page).to have_css '.drawer-panel.max-w-lg'
    end

    it 'renders wide size' do
      @options.merge!(size: :wide)
      render_inline(component)

      expect(page).to have_css '.drawer-panel.max-w-2xl'
    end

    it 'renders extra_wide size' do
      @options.merge!(size: :extra_wide)
      render_inline(component)

      expect(page).to have_css '.drawer-panel.max-w-4xl'
    end
  end

  describe 'structure' do
    it 'renders overlay for closing' do
      render_inline(component)

      expect(page).to have_css '.drawer-overlay'
    end

    it 'renders drawer panel with Tailwind classes' do
      render_inline(component)

      expect(page).to have_css '.drawer-panel.bg-base-100.shadow-2xl'
    end
  end
end
