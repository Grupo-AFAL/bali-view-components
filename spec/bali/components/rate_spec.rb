# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Rate::Component, type: :component do
  let(:options) { { form: movie_form_builder, method: :rating, value: 3 } }
  let(:component) { described_class.new(**options) }

  describe 'basic rendering' do
    it 'renders with DaisyUI rating classes' do
      render_inline(component)

      expect(page).to have_css 'div.rating'
    end

    it 'renders 5 star inputs by default' do
      render_inline(component)

      expect(page).to have_css 'input.mask.mask-star-2', count: 5
    end

    it 'renders with role radiogroup for accessibility' do
      render_inline(component)

      expect(page).to have_css 'div.rating[role="radiogroup"]'
    end

    it 'renders with aria-label' do
      render_inline(component)

      expect(page).to have_css 'div.rating[aria-label="Rating"]'
    end

    it 'marks the correct star as checked' do
      render_inline(component)

      expect(page).to have_css 'input[value="3"][checked]'
    end
  end

  describe 'sizes' do
    described_class::SIZES.each do |size_key, size_class|
      it "renders #{size_key} size" do
        render_inline(described_class.new(value: 3, size: size_key, readonly: true))

        expect(page).to have_css "div.rating.#{size_class}"
      end
    end
  end

  describe 'colors' do
    described_class::COLORS.each do |color_key, color_class|
      it "renders #{color_key} color" do
        render_inline(described_class.new(value: 3, color: color_key, readonly: true))

        expect(page).to have_css "input.#{color_class}"
      end
    end
  end

  describe 'auto_submit mode' do
    before { options[:auto_submit] = true }

    it 'renders button tags for each star' do
      render_inline(component)

      expect(page).to have_css 'button.mask.mask-star-2', count: 5
    end

    it 'sets correct name and value on buttons' do
      render_inline(component)

      expect(page).to have_css 'button[name="movie[rating]"][value="1"]'
      expect(page).to have_css 'button[name="movie[rating]"][value="5"]'
    end

    it 'sets buttons as submit type' do
      render_inline(component)

      expect(page).to have_css 'button[type="submit"]', count: 5
    end

    it 'includes aria-label on buttons' do
      render_inline(component)

      expect(page).to have_css 'button[aria-label="1 stars"]'
      expect(page).to have_css 'button[aria-label="5 stars"]'
    end
  end

  describe 'readonly mode' do
    let(:component) { described_class.new(value: 4, readonly: true) }

    it 'renders disabled inputs' do
      render_inline(component)

      expect(page).to have_css 'input[disabled]', count: 5
    end

    it 'does not require form or method' do
      expect { render_inline(component) }.not_to raise_error
    end

    it 'does not have role radiogroup' do
      render_inline(component)

      expect(page).not_to have_css '[role="radiogroup"]'
    end

    it 'marks the correct star as checked' do
      render_inline(component)

      expect(page).to have_css 'input[disabled][checked]', count: 1
    end
  end

  describe 'form integration' do
    it 'uses form radio_button helper' do
      render_inline(component)

      expect(page).to have_css 'input[type="radio"][name="movie[rating]"]', count: 5
    end

    it 'generates correct IDs for each star' do
      render_inline(component)

      expect(page).to have_css 'input[id="movie_rating_1"]'
      expect(page).to have_css 'input[id="movie_rating_5"]'
    end
  end

  describe 'custom scale' do
    it 'renders specified number of stars' do
      render_inline(described_class.new(value: 2, scale: 1..3, readonly: true))

      expect(page).to have_css 'input.mask-star-2', count: 3
    end

    it 'supports 10-star scale' do
      render_inline(described_class.new(value: 7, scale: 1..10, readonly: true))

      expect(page).to have_css 'input.mask-star-2', count: 10
    end
  end

  describe 'options passthrough' do
    it 'accepts custom class' do
      render_inline(described_class.new(value: 3, readonly: true, class: 'my-custom-class'))

      expect(page).to have_css 'div.rating.my-custom-class'
    end

    it 'accepts custom aria-label' do
      render_inline(described_class.new(value: 3, readonly: true, 'aria-label': 'Movie rating'))

      expect(page).to have_css 'div.rating[aria-label="Movie rating"]'
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(value: 3, readonly: true, data: { testid: 'rating' }))

      expect(page).to have_css 'div.rating[data-testid="rating"]'
    end
  end
end
