# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Drawer::Component, type: :component do
  let(:component) { described_class.new(**@options) }

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
    described_class::SIZES.each do |size_key, size_class|
      it "renders #{size_key} size with #{size_class}" do
        @options.merge!(size: size_key)
        render_inline(component)

        expect(page).to have_css ".drawer-panel.#{size_class}"
      end
    end

    it 'renders medium size by default' do
      render_inline(component)

      expect(page).to have_css '.drawer-panel.max-w-lg'
    end
  end

  describe 'positions' do
    it 'positions drawer on right by default' do
      render_inline(component)

      expect(page).to have_css '.drawer-panel.right-0'
    end

    it 'positions drawer on left' do
      @options.merge!(position: :left)
      render_inline(component)

      expect(page).to have_css '.drawer-panel.left-0'
    end

    it 'uses correct transform for left position' do
      @options.merge!(position: :left)
      render_inline(component)

      expect(page).to have_css '.drawer-panel.-translate-x-full'
    end

    it 'uses correct transform for right position' do
      @options.merge!(position: :right)
      render_inline(component)

      expect(page).to have_css '.drawer-panel.translate-x-full'
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

  describe 'unique IDs' do
    it 'generates unique drawer_id by default' do
      render_inline(component)

      id = page.find('[role="dialog"]')['id']
      expect(id).to match(/drawer-[a-f0-9]{8}/)
    end

    it 'uses provided drawer_id' do
      @options.merge!(drawer_id: 'my-settings-drawer')
      render_inline(component)

      expect(page).to have_css '#my-settings-drawer'
    end
  end

  describe 'accessibility' do
    it 'has role="dialog"' do
      render_inline(component)

      expect(page).to have_css '[role="dialog"]'
    end

    it 'has aria-modal="true"' do
      render_inline(component)

      expect(page).to have_css '[aria-modal="true"]'
    end

    it 'connects aria-labelledby to title when title is provided' do
      @options.merge!(title: 'Settings')
      render_inline(component)

      dialog = page.find('[role="dialog"]')
      title_id = dialog['aria-labelledby']
      expect(page).to have_css "##{title_id}", text: 'Settings'
    end

    it 'does not add aria-labelledby when no title is provided' do
      render_inline(component)

      dialog = page.find('[role="dialog"]')
      expect(dialog['aria-labelledby']).to be_nil
    end

    it 'has close button with aria-label' do
      @options.merge!(title: 'Settings')
      render_inline(component)

      expect(page).to have_css 'button[aria-label="Close drawer"]'
    end

    it 'overlay has aria-hidden="true"' do
      render_inline(component)

      expect(page).to have_css '.drawer-overlay[aria-hidden="true"]'
    end

    it 'has escape key handling via data-action' do
      render_inline(component)

      dialog = page.find('[role="dialog"]')
      expect(dialog['data-action']).to include('keydown.esc->drawer#close')
    end
  end

  describe 'title and header' do
    it 'renders title when provided' do
      @options.merge!(title: 'My Drawer')
      render_inline(component)

      expect(page).to have_css 'h2', text: 'My Drawer'
    end

    it 'renders header slot' do
      render_inline(component) do |drawer|
        drawer.with_header { '<span>Custom Header</span>'.html_safe }
        '<p>Content</p>'.html_safe
      end

      expect(page).to have_css '.drawer-header span', text: 'Custom Header'
    end

    it 'renders close button when header or title is present' do
      @options.merge!(title: 'My Drawer')
      render_inline(component)

      expect(page).to have_css '.drawer-header button[data-action="drawer#close"]'
    end

    it 'does not render header section when no title or header slot' do
      render_inline(component)

      expect(page).not_to have_css '.drawer-header'
    end
  end

  describe 'footer slot' do
    it 'renders footer slot' do
      render_inline(component) do |drawer|
        drawer.with_footer { '<button>Save</button>'.html_safe }
        '<p>Content</p>'.html_safe
      end

      expect(page).to have_css '.drawer-footer button', text: 'Save'
    end

    it 'does not render footer section when no footer slot' do
      render_inline(component)

      expect(page).not_to have_css '.drawer-footer'
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      @options.merge!(class: 'custom-drawer')
      render_inline(component)

      expect(page).to have_css '.drawer-component.custom-drawer'
    end

    it 'accepts data attributes' do
      @options.merge!(data: { testid: 'test-drawer' })
      render_inline(component)

      expect(page).to have_css '[data-testid="test-drawer"]'
    end

    it 'merges data attributes with defaults' do
      @options.merge!(data: { custom: 'value' })
      render_inline(component)

      dialog = page.find('[role="dialog"]')
      expect(dialog['data-controller']).to eq('drawer')
      expect(dialog['data-custom']).to eq('value')
    end
  end
end
