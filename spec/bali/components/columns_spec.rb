# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Columns::Component, type: :component do
  let(:component) { described_class.new }

  describe 'basic rendering' do
    it 'renders container with CSS Grid classes' do
      render_inline(component) do |c|
        c.with_column { 'First' }
        c.with_column { 'Second' }
      end

      expect(page).to have_css 'div.grid.grid-cols-12.gap-4'
    end

    it 'renders columns with default col-span-12 sizing' do
      render_inline(component) do |c|
        c.with_column { 'First' }
        c.with_column { 'Second' }
      end

      expect(page).to have_css 'div.col-span-12', count: 2
    end
  end

  describe 'gap sizes' do
    described_class::GAPS.each do |gap_name, gap_class|
      it "applies #{gap_name} gap with #{gap_class}" do
        render_inline(described_class.new(gap: gap_name)) do |c|
          c.with_column { 'Content' }
        end

        expect(page).to have_css "div.grid.#{gap_class}"
      end
    end

    it 'defaults to md gap when invalid gap provided' do
      render_inline(described_class.new(gap: :invalid)) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.grid.gap-4'
    end
  end

  describe 'column sizes' do
    Bali::Columns::Column::Component::SIZES.each do |size_name, size_class|
      it "applies #{size_name} size with #{size_class}" do
        render_inline(component) do |c|
          c.with_column(size: size_name) { "#{size_name} column" }
        end

        expect(page).to have_css "div.#{size_class}"
      end
    end
  end

  describe 'column offsets' do
    Bali::Columns::Column::Component::OFFSETS.each do |offset_name, offset_class|
      it "applies #{offset_name} offset with #{offset_class}" do
        render_inline(component) do |c|
          c.with_column(offset: offset_name) { "#{offset_name} offset" }
        end

        expect(page).to have_css "div.#{offset_class}"
      end
    end
  end

  describe 'combined size and offset' do
    it 'applies both size and offset' do
      render_inline(component) do |c|
        c.with_column(size: :half, offset: :quarter) { 'Combined' }
      end

      column = page.find('div.col-span-6')
      expect(column[:class]).to include('col-start-4')
    end
  end

  describe 'custom classes passthrough' do
    it 'accepts custom classes on container' do
      render_inline(described_class.new(class: 'custom-container')) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.grid.custom-container'
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
