# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Button::Component, type: :component do
  describe 'basic rendering' do
    it 'renders a button element with btn class' do
      render_inline(described_class.new) { 'Click me' }

      expect(page).to have_css('button.btn')
      expect(page).to have_button('Click me')
    end

    it 'renders with type=button by default' do
      render_inline(described_class.new) { 'Click me' }

      expect(page).to have_css('button[type="button"]')
    end

    it 'renders with type=submit when specified' do
      render_inline(described_class.new(type: :submit)) { 'Submit' }

      expect(page).to have_css('button[type="submit"]')
    end
  end

  describe 'variants' do
    %i[primary secondary accent info success warning error ghost link neutral outline].each do |variant|
      it "renders #{variant} variant" do
        render_inline(described_class.new(variant: variant)) { 'Button' }

        expect(page).to have_css("button.btn.btn-#{variant}")
      end
    end
  end

  describe 'sizes' do
    %i[xs sm lg xl].each do |size|
      it "renders #{size} size" do
        render_inline(described_class.new(size: size)) { 'Button' }

        expect(page).to have_css("button.btn.btn-#{size}")
      end
    end

    it 'renders md size without extra class' do
      render_inline(described_class.new(size: :md)) { 'Button' }

      expect(page).to have_css('button.btn')
      expect(page).not_to have_css('button.btn-md')
    end
  end

  describe 'disabled state' do
    it 'renders with disabled attribute' do
      render_inline(described_class.new(disabled: true)) { 'Disabled' }

      expect(page).to have_css('button.btn.btn-disabled[disabled]')
    end
  end

  describe 'loading state' do
    it 'renders with loading spinner' do
      render_inline(described_class.new(loading: true)) { 'Loading' }

      expect(page).to have_css('button.btn.loading')
      expect(page).to have_css('button .loading-spinner')
    end
  end

  describe 'icons' do
    it 'renders with icon_name' do
      render_inline(described_class.new(icon_name: 'plus')) { 'Add' }

      expect(page).to have_css('button.btn')
      # Icon component should be rendered
    end

    it 'renders with icon slot' do
      render_inline(described_class.new) do |button|
        button.with_icon('check')
        'Save'
      end

      expect(page).to have_css('button.btn')
    end

    it 'renders with icon_right slot' do
      render_inline(described_class.new) do |button|
        button.with_icon_right('arrow-right')
        'Next'
      end

      expect(page).to have_css('button.btn')
    end
  end

  describe 'custom attributes' do
    it 'passes data attributes' do
      render_inline(described_class.new(data: { action: 'modal#close' })) { 'Close' }

      expect(page).to have_css('button.btn[data-action="modal#close"]')
    end

    it 'merges custom classes' do
      render_inline(described_class.new(class: 'w-full')) { 'Full Width' }

      expect(page).to have_css('button.btn.w-full')
    end
  end
end
