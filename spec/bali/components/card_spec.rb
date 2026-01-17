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

      expect(page).to have_css '.card.shadow-sm'
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
      # Should NOT have double figure tags
      expect(page).not_to have_css 'figure figure'
    end

    it 'renders image with alt text' do
      render_inline(described_class.new) do |c|
        c.with_image(src: '/image.png', alt: 'Product photo')
      end

      expect(page).to have_css 'figure img[alt="Product photo"]'
    end

    it 'renders image with figure_class' do
      render_inline(described_class.new) do |c|
        c.with_image(src: '/image.png', figure_class: 'px-4 pt-4')
      end

      expect(page).to have_css 'figure.px-4.pt-4 img'
    end

    it 'passes data attributes to image' do
      render_inline(described_class.new) do |c|
        c.with_image(src: '/image.png', data: { controller: 'lightbox' }, loading: 'lazy')
      end

      expect(page).to have_css 'figure img[data-controller="lightbox"][loading="lazy"]'
    end
  end

  describe 'title slot' do
    it 'renders a card with title slot' do
      render_inline(described_class.new) do |c|
        c.with_title('Card Title')
        'Content'
      end

      expect(page).to have_css '.card-body h2.card-title', text: 'Card Title'
    end

    it 'renders title with custom class' do
      render_inline(described_class.new) do |c|
        c.with_title('Title', class: 'text-primary')
      end

      expect(page).to have_css 'h2.card-title.text-primary'
    end
  end

  describe 'header slot' do
    it 'renders header with title inside card-body' do
      render_inline(described_class.new) do |c|
        c.with_header(title: 'Header Title')
        'Content'
      end

      expect(page).to have_css '.card-body h2.card-title', text: 'Header Title'
    end

    it 'renders header with subtitle' do
      render_inline(described_class.new) do |c|
        c.with_header(title: 'Main Title', subtitle: 'A helpful subtitle')
      end

      expect(page).to have_css '.card-body h2.card-title', text: 'Main Title'
      expect(page).to have_css '.card-body p.text-sm', text: 'A helpful subtitle'
    end

    it 'renders header with icon' do
      render_inline(described_class.new) do |c|
        c.with_header(title: 'Settings', icon: 'cog')
      end

      expect(page).to have_css '.card-body .flex.items-center.gap-3'
      expect(page).to have_css 'h2.card-title', text: 'Settings'
    end

    it 'renders header with badge' do
      render_inline(described_class.new) do |c|
        c.with_header(title: 'Notifications') do |header|
          header.with_badge { 'NEW' }
        end
      end

      expect(page).to have_css 'h2.card-title', text: 'Notifications'
      expect(page).to have_text 'NEW'
    end

    it 'renders header with icon, subtitle, and badge' do
      render_inline(described_class.new) do |c|
        c.with_header(title: 'Dashboard', subtitle: 'Overview of your data', icon: 'home') do |header|
          header.with_badge { 'Beta' }
        end
      end

      expect(page).to have_css '.flex.items-center.gap-3'
      expect(page).to have_css 'h2.card-title', text: 'Dashboard'
      expect(page).to have_css 'p.text-sm', text: 'Overview of your data'
      expect(page).to have_text 'Beta'
    end
  end

  describe 'actions' do
    it 'renders link actions with btn class' do
      render_inline(described_class.new) do |c|
        c.with_action(href: '/path', class: 'btn-primary') { 'Link to path' }
      end

      expect(page).to have_css '.card-actions a.btn.btn-primary[href="/path"]', text: 'Link to path'
    end

    it 'renders button actions with btn class' do
      render_inline(described_class.new) do |c|
        c.with_action(class: 'btn-ghost') { 'Click me' }
      end

      expect(page).to have_css '.card-actions button.btn.btn-ghost[type="button"]', text: 'Click me'
    end

    it 'renders button with data attributes' do
      render_inline(described_class.new) do |c|
        c.with_action(data: { action: 'click->modal#open' }) { 'Open Modal' }
      end

      expect(page).to have_css '.card-actions button.btn[data-action="click->modal#open"]'
    end
  end

  describe 'custom image slot' do
    it 'renders a card with custom image content' do
      render_inline(described_class.new) do |c|
        c.with_image do
          '<div class="image-content">Custom content in image</div>'.html_safe
        end

        c.with_action(href: '/path') { 'Link to path' }

        '<div class="content">Content</div>'.html_safe
      end

      expect(page).to have_css 'figure .image-content', text: 'Custom content in image'
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
