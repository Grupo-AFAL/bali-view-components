# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Columns::Component, type: :component do
  let(:component) { described_class.new }

  describe 'basic rendering' do
    it 'renders container with flexbox classes' do
      render_inline(component) do |c|
        c.with_column { 'First' }
        c.with_column { 'Second' }
      end

      expect(page).to have_css 'div.flex.flex-wrap.gap-4'
    end

    it 'renders columns with default basis-full and grow' do
      render_inline(component) do |c|
        c.with_column { 'First' }
        c.with_column { 'Second' }
      end

      expect(page).to have_css 'div.basis-full.grow', count: 2
    end
  end

  describe 'gap sizes' do
    described_class::GAPS.each do |gap_name, gap_class|
      it "applies #{gap_name} gap with #{gap_class}" do
        render_inline(described_class.new(gap: gap_name)) do |c|
          c.with_column { 'Content' }
        end

        expect(page).to have_css "div.flex.#{gap_class}"
      end
    end

    it 'defaults to md gap when invalid gap provided' do
      render_inline(described_class.new(gap: :invalid)) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.flex.gap-4'
    end
  end

  describe 'column sizes' do
    {
      full: 'basis-full',
      half: 'basis-1/2',
      third: 'basis-1/3',
      two_thirds: 'basis-2/3',
      quarter: 'basis-1/4',
      three_quarters: 'basis-3/4'
    }.each do |size_name, size_class|
      it "applies #{size_name} size with #{size_class} and grow" do
        render_inline(component) do |c|
          c.with_column(size: size_name) { "#{size_name} column" }
        end

        # Escape the slash in class names for CSS selector
        css_class = size_class.gsub('/', '\/')
        expect(page).to have_css "div.#{css_class}.grow"
      end
    end

    it 'applies auto size with shrink-0 and no grow' do
      render_inline(component) do |c|
        c.with_column(size: :auto) { 'auto column' }
      end

      expect(page).to have_css 'div.shrink-0'
      expect(page).not_to have_css 'div.shrink-0.grow'
    end
  end

  describe 'custom classes passthrough' do
    it 'accepts custom classes on container' do
      render_inline(described_class.new(class: 'custom-container')) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.flex.custom-container'
    end

    it 'accepts custom classes on column' do
      render_inline(component) do |c|
        c.with_column(class: 'custom-column') { 'Content' }
      end

      expect(page).to have_css 'div.custom-column'
    end

    it 'accepts data attributes on container' do
      render_inline(described_class.new(data: { testid: 'columns' })) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div[data-testid="columns"]'
    end

    it 'accepts data attributes on column' do
      render_inline(component) do |c|
        c.with_column(data: { testid: 'column' }) { 'Content' }
      end

      expect(page).to have_css 'div[data-testid="column"]'
    end
  end

  describe 'min-w-0 overflow prevention' do
    it 'applies min-w-0 to prevent content overflow' do
      render_inline(component) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.min-w-0'
    end
  end
end
