# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Link::Component, type: :component do
  describe 'default' do
    it 'renders a basic link' do
      render_inline(described_class.new(name: 'Click me!', href: '#'))

      expect(page).to have_css 'a', text: 'Click me!'
      expect(page).to have_css 'a[href="#"]'
    end

    it 'renders with DaisyUI link class' do
      render_inline(described_class.new(name: 'Click me!', href: '#'))

      expect(page).to have_css 'a.link'
    end

    it 'includes inline-flex for icon alignment' do
      render_inline(described_class.new(name: 'Click me!', href: '#'))

      expect(page).to have_css 'a.inline-flex'
    end
  end

  describe 'variants' do
    described_class::VARIANTS.each_key do |variant|
      it "renders #{variant} variant" do
        render_inline(described_class.new(name: 'Click', href: '#', variant: variant))

        expect(page).to have_css "a.btn.#{described_class::VARIANTS[variant]}", text: 'Click'
        expect(page).to have_css 'a[href="#"]'
      end
    end
  end

  describe 'sizes' do
    it 'renders small button' do
      render_inline(described_class.new(name: 'Small', href: '#', variant: :primary, size: :sm))

      expect(page).to have_css 'a.btn.btn-sm'
    end

    it 'renders large button' do
      render_inline(described_class.new(name: 'Large', href: '#', variant: :primary, size: :lg))

      expect(page).to have_css 'a.btn.btn-lg'
    end

    it 'ignores size without variant' do
      render_inline(described_class.new(name: 'Link', href: '#', size: :lg))

      expect(page).not_to have_css 'a.btn-lg'
      expect(page).to have_css 'a.link'
    end
  end

  describe 'styles' do
    it 'renders outline style' do
      render_inline(described_class.new(name: 'Outline', href: '#', variant: :primary, style: :outline))

      expect(page).to have_css 'a.btn.btn-primary.btn-outline'
    end

    it 'renders soft style' do
      render_inline(described_class.new(name: 'Soft', href: '#', variant: :primary, style: :soft))

      expect(page).to have_css 'a.btn.btn-primary.btn-soft'
    end

    it 'applies style as button when used without variant' do
      render_inline(described_class.new(name: 'Outline', href: '#', style: :outline))

      expect(page).to have_css 'a.btn.btn-outline'
      expect(page).not_to have_css 'a.link'
    end

    it 'combines style with size' do
      render_inline(described_class.new(name: 'Small Outline', href: '#', variant: :primary, style: :outline, size: :sm))

      expect(page).to have_css 'a.btn.btn-primary.btn-outline.btn-sm'
    end
  end

  describe 'with icon slot' do
    it 'renders icon via slot' do
      render_inline(described_class.new(name: 'Click', href: '#')) do |c|
        c.with_icon('star')
      end

      expect(page).to have_css 'a', text: 'Click'
      expect(page).to have_css 'span.icon-component'
    end

    it 'renders icon with button variant' do
      render_inline(described_class.new(name: 'Click', href: '#', variant: :primary)) do |c|
        c.with_icon('star')
      end

      expect(page).to have_css 'a.btn', text: 'Click'
      expect(page).to have_css 'span.icon-component'
    end
  end

  describe 'with icon_name parameter' do
    it 'renders icon from icon_name' do
      render_inline(described_class.new(name: 'Click', href: '#', icon_name: 'star'))

      expect(page).to have_css 'span.icon-component'
    end
  end

  describe 'with icon_right slot' do
    it 'renders icon on the right' do
      render_inline(described_class.new(name: 'Next', href: '#', variant: :primary)) do |c|
        c.with_icon_right('chevron-right')
      end

      expect(page).to have_css 'a.btn', text: 'Next'
      expect(page).to have_css 'span.icon-component'
    end
  end

  describe 'active indicator' do
    context 'when current path is active' do
      it 'does not add the active class when active is false' do
        render_inline(described_class.new(name: 'Link', href: '/items', active_path: '/items',
                                          active: false))

        expect(page).not_to have_css 'a.active'
      end

      it 'adds the active class when active is true' do
        render_inline(described_class.new(name: 'Link', href: '/items', active_path: '/items',
                                          active: true))

        expect(page).to have_css 'a.active'
      end

      it 'adds the active class when active is nil (auto-detect)' do
        render_inline(described_class.new(name: 'Link', href: '/items', active_path: '/items'))

        expect(page).to have_css 'a.active'
      end
    end

    context 'when current path is not active' do
      it 'adds the active class when active is true (forced)' do
        render_inline(described_class.new(name: 'Link', href: '/items', active_path: '/movies',
                                          active: true))

        expect(page).to have_css 'a.active'
      end

      it 'does not add the active class when active is false' do
        render_inline(described_class.new(name: 'Link', href: '/items', active_path: '/movies',
                                          active: false))

        expect(page).not_to have_css 'a.active'
      end

      it 'does not add the active class when active is nil (auto-detect)' do
        render_inline(described_class.new(name: 'Link', href: '/items', active_path: '/movies'))

        expect(page).not_to have_css 'a.active'
      end
    end
  end

  describe 'method parameter' do
    it 'renders turbo method for non-GET requests' do
      render_inline(described_class.new(name: 'Delete', href: '#', method: :post))

      expect(page).to have_css 'a[data-turbo-method="post"]', text: 'Delete'
    end

    it 'renders data-method for GET requests' do
      render_inline(described_class.new(name: 'Fetch', href: '#', method: :get))

      expect(page).to have_css 'a.link', text: 'Fetch'
      expect(page).not_to have_css 'a[data-turbo-method="get"]'
      expect(page).to have_css 'a[data-method="get"]'
    end
  end

  describe 'disabled' do
    it 'adds btn-disabled class when disabled with variant' do
      render_inline(described_class.new(name: 'Disabled', href: '/', variant: :primary,
                                        disabled: true))

      expect(page).to have_css 'a.btn-disabled'
      expect(page).not_to have_css 'a[href]'
    end

    it 'does not add btn-disabled class for plain disabled link' do
      render_inline(described_class.new(name: 'Disabled', href: '/', disabled: true))

      expect(page).not_to have_css 'a.btn-disabled'
      expect(page).not_to have_css 'a[href]'
    end
  end

  describe 'plain mode' do
    it 'renders with flex classes for menu items' do
      render_inline(described_class.new(name: 'Menu Item', href: '#', plain: true))

      expect(page).to have_css 'a.flex.items-center.gap-2'
      expect(page).not_to have_css 'a.link'
    end
  end

  describe 'authorization' do
    it 'renders when authorized' do
      render_inline(described_class.new(name: 'Link', href: '#', authorized: true))

      expect(page).to have_css 'a', text: 'Link'
    end

    it 'does not render when not authorized' do
      render_inline(described_class.new(name: 'Link', href: '#', authorized: false))

      expect(page).not_to have_css 'a'
    end
  end

  describe 'custom options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(name: 'Link', href: '#', class: 'custom-class'))

      expect(page).to have_css 'a.custom-class'
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(name: 'Link', href: '#', data: { testid: 'test-link' }))

      expect(page).to have_css 'a[data-testid="test-link"]'
    end

    it 'accepts id attribute' do
      render_inline(described_class.new(name: 'Link', href: '#', id: 'my-link'))

      expect(page).to have_css 'a#my-link'
    end
  end

  describe 'content block' do
    it 'renders custom content' do
      render_inline(described_class.new(href: '#', variant: :primary)) do
        'Custom Content'
      end

      expect(page).to have_css 'a.btn', text: 'Custom Content'
    end
  end

  describe 'deprecated type parameter' do
    it 'supports type for backwards compatibility' do
      render_inline(described_class.new(name: 'Button', href: '#', type: :primary))

      expect(page).to have_css 'a.btn.btn-primary', text: 'Button'
    end

    it 'prefers variant over type when both are provided' do
      render_inline(described_class.new(name: 'Button', href: '#', variant: :error, type: :primary))

      expect(page).to have_css 'a.btn.btn-error', text: 'Button'
      expect(page).not_to have_css 'a.btn-primary'
    end
  end
end
