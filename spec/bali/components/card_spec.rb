# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Card::Component, type: :component do
  describe 'basic rendering' do
    it 'renders a card with DaisyUI classes' do
      render_inline(described_class.new) do
        '<div class="content">Content</div>'.html_safe
      end

      expect(page).to have_css '.card.bg-base-100'
      expect(page).to have_css '.card-body', text: 'Content'
    end

    it 'renders with shadow by default' do
      render_inline(described_class.new) do
        'Content'
      end

      expect(page).to have_css '.card.shadow-lg'
    end
  end

  describe 'image' do
    it 'renders a card with a clickable image' do
      render_inline(described_class.new) do |c|
        c.with_image(src: '/image.png', href: '/path/to/page')
      end

      expect(page).to have_css 'figure a[href="/path/to/page"] img[src="/image.png"]'
    end

    it 'renders a card with non-clickable image' do
      render_inline(described_class.new) do |c|
        c.with_image(src: '/image.png')
      end

      expect(page).to have_css 'figure img[src="/image.png"]'
    end
  end

  describe 'footer items' do
    it 'renders footer items in card-actions' do
      render_inline(described_class.new) do |c|
        c.with_footer_item(href: '/path', class: 'btn-primary') { 'Link to path' }
      end

      expect(page).to have_css '.card-actions a.btn[href="/path"]', text: 'Link to path'
    end

    it 'renders regular footer item without href' do
      render_inline(described_class.new) do |c|
        c.with_footer_item do
          '<span class="hola">Hola</span>'.html_safe
        end
      end

      expect(page).to have_css '.card-actions span.hola', text: 'Hola'
    end
  end

  describe 'custom image slot' do
    it 'renders a card with custom image content' do
      render_inline(described_class.new) do |c|
        c.with_image do
          '<div class="image-content">Custom content in image</div>'.html_safe
        end

        c.with_footer_item(href: '/path') { 'Link to path' }

        '<div class="content">Content</div>'.html_safe
      end

      expect(page).to have_css '.image-content', text: 'Custom content in image'
    end
  end

  describe 'styles' do
    it 'renders bordered style' do
      render_inline(described_class.new(style: :bordered)) do
        'Content'
      end

      expect(page).to have_css '.card.card-border'
    end

    it 'renders dash style' do
      render_inline(described_class.new(style: :dash)) do
        'Content'
      end

      expect(page).to have_css '.card.card-dash'
    end
  end

  describe 'layouts' do
    it 'renders side layout' do
      render_inline(described_class.new(side: true)) do
        'Content'
      end

      expect(page).to have_css '.card.card-side'
    end

    it 'renders image-full layout' do
      render_inline(described_class.new(image_full: true)) do
        'Content'
      end

      expect(page).to have_css '.card.image-full'
    end
  end

  describe 'sizes' do
    it 'renders small size' do
      render_inline(described_class.new(size: :sm)) do
        'Content'
      end

      expect(page).to have_css '.card.card-sm'
    end

    it 'renders large size' do
      render_inline(described_class.new(size: :lg)) do
        'Content'
      end

      expect(page).to have_css '.card.card-lg'
    end
  end
end
