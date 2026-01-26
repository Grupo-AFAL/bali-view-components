# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Carousel::Component, type: :component do
  let(:options) { {} }
  let(:component) { described_class.new(**options) }

  def slide_image(text = 'Slide')
    "<img src=\"https://placehold.co/320x244?text=#{text}\" />".html_safe
  end

  def render_with_items(component, count: 3)
    render_inline(component) do |c|
      count.times do |i|
        c.with_item { slide_image("Slide#{i + 1}") }
      end
    end
  end

  describe 'basic rendering' do
    it 'renders the carousel structure' do
      render_with_items(component)

      expect(page).to have_css '.glide .glide__track .glide__slides'
    end

    it 'renders all items as slides' do
      render_with_items(component, count: 5)

      expect(page).to have_css '.glide__slide', count: 5
    end

    it 'does not render without items' do
      render_inline(component)

      expect(page).not_to have_css '.glide'
    end
  end

  describe 'options' do
    it 'applies start_at value' do
      options[:start_at] = 2
      render_with_items(component)

      expect(page).to have_css 'div[data-carousel-start-at-value="2"]'
    end

    it 'applies slides_per_view value' do
      options[:slides_per_view] = 3
      render_with_items(component)

      expect(page).to have_css 'div[data-carousel-per-view-value="3"]'
    end

    it 'applies gap value' do
      options[:gap] = 16
      render_with_items(component)

      expect(page).to have_css 'div[data-carousel-gap-value="16"]'
    end

    it 'applies focus_at value' do
      options[:focus_at] = :center
      render_with_items(component)

      expect(page).to have_css 'div[data-carousel-focus-at-value="center"]'
    end

    context 'with autoplay' do
      it 'accepts symbol shorthand' do
        options[:autoplay] = :medium
        render_with_items(component)

        expect(page).to have_css 'div[data-carousel-autoplay-value="3000"]'
      end

      it 'accepts integer value directly' do
        options[:autoplay] = 5000
        render_with_items(component)

        expect(page).to have_css 'div[data-carousel-autoplay-value="5000"]'
      end

      it 'disables autoplay by default' do
        render_with_items(component)

        expect(page).to have_css 'div[data-carousel-autoplay-value="false"]'
      end
    end
  end

  describe 'arrows slot' do
    it 'renders arrows when requested' do
      render_inline(component) do |c|
        c.with_arrows
        c.with_item { slide_image }
      end

      expect(page).to have_css '.glide__arrows'
      expect(page).to have_css 'button.glide__arrow--left'
      expect(page).to have_css 'button.glide__arrow--right'
    end

    it 'includes accessibility labels on arrows' do
      render_inline(component) do |c|
        c.with_arrows
        c.with_item { slide_image }
      end

      expect(page).to have_css 'button[aria-label="Previous slide"]'
      expect(page).to have_css 'button[aria-label="Next slide"]'
    end

    it 'allows custom icons' do
      render_inline(component) do |c|
        c.with_arrows(previous_icon: 'chevron-left', next_icon: 'chevron-right')
        c.with_item { slide_image }
      end

      expect(page).to have_css '.glide__arrow--left svg'
      expect(page).to have_css '.glide__arrow--right svg'
    end

    it 'can be hidden' do
      render_inline(component) do |c|
        c.with_arrows(hidden: true)
        c.with_item { slide_image }
      end

      expect(page).not_to have_css '.glide__arrows'
    end
  end

  describe 'bullets slot' do
    it 'renders bullets matching item count' do
      render_inline(component) do |c|
        c.with_bullets
        5.times { |i| c.with_item { slide_image(i) } }
      end

      expect(page).to have_css '.glide__bullets'
      expect(page).to have_css '.glide__bullet', count: 5
    end

    it 'includes accessibility attributes on bullets' do
      render_inline(component) do |c|
        c.with_bullets
        3.times { |i| c.with_item { slide_image(i) } }
      end

      expect(page).to have_css '.glide__bullets[role="tablist"][aria-label="Slide navigation"]'
      expect(page).to have_css 'button[role="tab"][aria-label="Go to slide 1"]'
      expect(page).to have_css 'button[role="tab"][aria-label="Go to slide 2"]'
      expect(page).to have_css 'button[role="tab"][aria-label="Go to slide 3"]'
    end

    it 'can be hidden' do
      render_inline(component) do |c|
        c.with_bullets(hidden: true)
        c.with_item { slide_image }
      end

      expect(page).not_to have_css '.glide__bullets'
    end

    it 'does not render with zero items' do
      render_inline(component, &:with_bullets)

      expect(page).not_to have_css '.glide__bullets'
    end
  end

  describe 'constants' do
    it 'has frozen DEFAULTS' do
      expect(described_class::DEFAULTS).to be_frozen
      expect(described_class::DEFAULTS).to include(
        start_at: 0,
        slides_per_view: 1,
        gap: 0,
        focus_at: :center
      )
    end

    it 'has frozen AUTOPLAY_INTERVALS' do
      expect(described_class::AUTOPLAY_INTERVALS).to be_frozen
      expect(described_class::AUTOPLAY_INTERVALS).to include(
        disabled: false,
        slow: 5000,
        medium: 3000,
        fast: 1500
      )
    end
  end
end

RSpec.describe Bali::Carousel::Arrows::Component, type: :component do
  it 'has frozen ICONS constant' do
    expect(described_class::ICONS).to be_frozen
    expect(described_class::ICONS).to eq(previous: 'arrow-left', next: 'arrow-right')
  end

  it 'uses translations for accessibility labels' do
    I18n.with_locale(:es) do
      render_inline(described_class.new)

      expect(page).to have_css 'button[aria-label="Diapositiva anterior"]'
      expect(page).to have_css 'button[aria-label="Diapositiva siguiente"]'
    end
  end

  it 'accepts custom classes' do
    render_inline(described_class.new(class: 'custom-arrows'))

    expect(page).to have_css '.glide__arrows.custom-arrows'
  end

  it 'accepts data attributes' do
    render_inline(described_class.new(data: { testid: 'arrows' }))

    expect(page).to have_css '[data-testid="arrows"]'
  end
end

RSpec.describe Bali::Carousel::Bullets::Component, type: :component do
  it 'uses translations for accessibility labels' do
    I18n.with_locale(:es) do
      render_inline(described_class.new(count: 3))

      expect(page).to have_css '.glide__bullets[aria-label="Navegación de diapositivas"]'
      expect(page).to have_css 'button[aria-label="Ir a diapositiva 1"]'
    end
  end

  it 'accepts custom classes' do
    render_inline(described_class.new(count: 3, class: 'custom-bullets'))

    expect(page).to have_css '.glide__bullets.custom-bullets'
  end

  it 'accepts data attributes' do
    render_inline(described_class.new(count: 3, data: { testid: 'bullets' }))

    expect(page).to have_css '[data-testid="bullets"]'
  end
end
