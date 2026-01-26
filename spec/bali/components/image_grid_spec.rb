# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::ImageGrid::Component, type: :component do
  describe 'grid configuration' do
    it 'renders a 4-column grid by default' do
      render_inline(described_class.new)

      expect(page).to have_css('.grid.grid-cols-4.gap-4')
    end

    it 'accepts custom column count' do
      render_inline(described_class.new(columns: 3))

      expect(page).to have_css('.grid.grid-cols-3')
    end

    it 'accepts custom gap' do
      render_inline(described_class.new(gap: :lg))

      expect(page).to have_css('.gap-6')
    end

    it 'accepts gap as string' do
      render_inline(described_class.new(gap: 'sm'))

      expect(page).to have_css('.gap-2')
    end

    it 'passes through custom classes' do
      render_inline(described_class.new(class: 'custom-class'))

      expect(page).to have_css('.grid.custom-class')
    end

    it 'passes through data attributes' do
      render_inline(described_class.new(data: { testid: 'image-grid' }))

      expect(page).to have_css('[data-testid="image-grid"]')
    end
  end

  describe 'column variants' do
    Bali::ImageGrid::Component::COLUMNS.each do |count, css_class|
      it "renders #{count}-column grid with #{css_class}" do
        render_inline(described_class.new(columns: count))

        expect(page).to have_css(".#{css_class}")
      end
    end
  end

  describe 'gap variants' do
    Bali::ImageGrid::Component::GAPS.each do |size, css_class|
      it "renders #{size} gap with #{css_class}" do
        render_inline(described_class.new(gap: size))

        expect(page).to have_css(".#{css_class}")
      end
    end
  end

  describe 'with images' do
    it 'renders image cards' do
      render_inline(described_class.new) do |c|
        c.with_image { '<img src="test.jpg">'.html_safe }
      end

      expect(page).to have_css('.card')
      expect(page).to have_css('img[src="test.jpg"]')
    end

    it 'renders multiple images' do
      render_inline(described_class.new) do |c|
        4.times do
          c.with_image { '<img src="test.jpg">'.html_safe }
        end
      end

      expect(page).to have_css('.card', count: 4)
    end

    it 'applies default aspect ratio' do
      render_inline(described_class.new) do |c|
        c.with_image { '<img src="test.jpg">'.html_safe }
      end

      expect(page).to have_css('figure.aspect-\\[3\\/2\\]')
    end

    it 'accepts custom aspect ratio symbol' do
      render_inline(described_class.new) do |c|
        c.with_image(aspect_ratio: :square) { '<img src="test.jpg">'.html_safe }
      end

      expect(page).to have_css('figure.aspect-square')
    end

    it 'accepts aspect ratio as string' do
      render_inline(described_class.new) do |c|
        c.with_image(aspect_ratio: 'video') { '<img src="test.jpg">'.html_safe }
      end

      expect(page).to have_css('figure.aspect-video')
    end
  end

  describe 'image with footer' do
    it 'renders footer when provided' do
      render_inline(described_class.new) do |c|
        c.with_image do |image|
          image.with_footer { 'Caption text' }
          '<img src="test.jpg">'.html_safe
        end
      end

      expect(page).to have_css('.card-body', text: 'Caption text')
    end

    it 'does not render footer element when not provided' do
      render_inline(described_class.new) do |c|
        c.with_image { '<img src="test.jpg">'.html_safe }
      end

      expect(page).not_to have_css('.card-body')
    end
  end
end

RSpec.describe Bali::ImageGrid::Image::Component, type: :component do
  describe 'aspect ratios' do
    it 'renders square aspect ratio' do
      render_inline(described_class.new(aspect_ratio: :square)) { '<img src="test.jpg">'.html_safe }

      expect(page).to have_css('figure.aspect-square')
    end

    it 'renders video aspect ratio' do
      render_inline(described_class.new(aspect_ratio: :video)) { '<img src="test.jpg">'.html_safe }

      expect(page).to have_css('figure.aspect-video')
    end

    it 'renders 3/2 aspect ratio' do
      render_inline(described_class.new(aspect_ratio: :'3/2')) { '<img src="test.jpg">'.html_safe }

      expect(page).to have_css('figure[class*="aspect-[3/2]"]')
    end

    it 'renders 4/3 aspect ratio' do
      render_inline(described_class.new(aspect_ratio: :'4/3')) { '<img src="test.jpg">'.html_safe }

      expect(page).to have_css('figure[class*="aspect-[4/3]"]')
    end

    it 'renders 4/5 aspect ratio' do
      render_inline(described_class.new(aspect_ratio: :'4/5')) { '<img src="test.jpg">'.html_safe }

      expect(page).to have_css('figure[class*="aspect-[4/5]"]')
    end

    it 'renders 16/9 aspect ratio' do
      render_inline(described_class.new(aspect_ratio: :'16/9')) { '<img src="test.jpg">'.html_safe }

      expect(page).to have_css('figure[class*="aspect-[16/9]"]')
    end
  end

  it 'applies card base classes' do
    render_inline(described_class.new) { '<img src="test.jpg">'.html_safe }

    expect(page).to have_css('.card.bg-base-100')
  end

  it 'passes through custom classes' do
    render_inline(described_class.new(class: 'shadow-lg')) { '<img src="test.jpg">'.html_safe }

    expect(page).to have_css('.card.shadow-lg')
  end

  it 'passes through data attributes' do
    render_inline(described_class.new(data: { image_id: '123' })) do
      '<img src="test.jpg">'.html_safe
    end

    expect(page).to have_css('[data-image-id="123"]')
  end

  it 'wraps content in figure with overflow hidden' do
    render_inline(described_class.new) { '<img src="test.jpg">'.html_safe }

    expect(page).to have_css('figure.overflow-hidden')
  end
end

RSpec.describe Bali::ImageGrid::Image::FooterComponent, type: :component do
  it 'renders footer with card-body classes' do
    render_inline(described_class.new) { 'Footer content' }

    expect(page).to have_css('.card-body.p-3', text: 'Footer content')
  end

  it 'passes through custom classes' do
    render_inline(described_class.new(class: 'bg-primary')) { 'Footer' }

    expect(page).to have_css('.card-body.bg-primary')
  end
end
