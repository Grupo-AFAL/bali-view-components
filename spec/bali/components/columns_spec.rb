# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Columns::Component, type: :component do
  let(:component) { described_class.new }

  describe 'basic rendering' do
    it 'renders container with columns class' do
      render_inline(component) do |c|
        c.with_column { 'First' }
        c.with_column { 'Second' }
      end

      expect(page).to have_css 'div.columns'
    end

    it 'renders columns with column class' do
      render_inline(component) do |c|
        c.with_column { 'First' }
        c.with_column { 'Second' }
      end

      expect(page).to have_css 'div.column', count: 2
    end
  end

  describe 'gap sizes (Tailwind-like)' do
    it 'applies default gap-md class' do
      render_inline(component) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.columns.gap-md'
    end

    described_class::GAPS.each do |gap_name, gap_class|
      it "applies #{gap_class} for gap: :#{gap_name}" do
        render_inline(described_class.new(gap: gap_name)) do |c|
          c.with_column { 'Content' }
        end

        expect(page).to have_css "div.columns.#{gap_class}"
      end
    end

    it 'falls back to gap-md for invalid gap' do
      render_inline(described_class.new(gap: :invalid)) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.columns.gap-md'
    end
  end

  describe 'wrap modifier' do
    it 'applies columns-wrap class when wrap: true' do
      render_inline(described_class.new(wrap: true)) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.columns.columns-wrap'
    end
  end

  describe 'alignment modifiers' do
    it 'applies columns-center when center: true' do
      render_inline(described_class.new(center: true)) do |c|
        c.with_column(size: :half) { 'Centered' }
      end

      expect(page).to have_css 'div.columns.columns-center'
    end

    it 'applies columns-middle when middle: true' do
      render_inline(described_class.new(middle: true)) do |c|
        c.with_column { 'Middle' }
      end

      expect(page).to have_css 'div.columns.columns-middle'
    end
  end

  describe 'mobile modifier' do
    it 'applies columns-mobile when mobile: true' do
      render_inline(described_class.new(mobile: true)) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.columns.columns-mobile'
    end
  end

  describe 'column sizes' do
    describe 'numeric sizes (col-1 through col-12)' do
      (1..12).each do |size|
        it "applies col-#{size} for size: #{size}" do
          render_inline(component) do |c|
            c.with_column(size: size) { "Column #{size}" }
          end

          expect(page).to have_css "div.column.col-#{size}"
        end
      end
    end

    describe 'symbolic sizes (fractions)' do
      {
        full: 'col-full',
        half: 'col-half',
        one_third: 'col-third',
        third: 'col-third',
        two_thirds: 'col-2-thirds',
        one_quarter: 'col-quarter',
        quarter: 'col-quarter',
        three_quarters: 'col-3-quarters',
        one_fifth: 'col-fifth',
        two_fifths: 'col-2-fifths',
        three_fifths: 'col-3-fifths',
        four_fifths: 'col-4-fifths'
      }.each do |size_name, size_class|
        it "applies #{size_class} for size: :#{size_name}" do
          render_inline(component) do |c|
            c.with_column(size: size_name) { "#{size_name} column" }
          end

          expect(page).to have_css "div.column.#{size_class}"
        end
      end
    end

    describe 'auto-width columns' do
      it 'applies col-auto class when auto: true' do
        render_inline(component) do |c|
          c.with_column(auto: true) { 'Auto' }
        end

        expect(page).to have_css 'div.column.col-auto'
      end
    end
  end

  describe 'column offsets' do
    describe 'numeric offsets' do
      (1..11).each do |offset|
        it "applies offset-#{offset} for offset: #{offset}" do
          render_inline(component) do |c|
            c.with_column(size: 6, offset: offset) { "Offset #{offset}" }
          end

          expect(page).to have_css "div.column.offset-#{offset}"
        end
      end
    end

    describe 'symbolic offsets' do
      {
        half: 'offset-half',
        one_third: 'offset-third',
        third: 'offset-third',
        two_thirds: 'offset-2-thirds',
        one_quarter: 'offset-quarter',
        quarter: 'offset-quarter',
        three_quarters: 'offset-3-quarters',
        one_fifth: 'offset-fifth',
        two_fifths: 'offset-2-fifths',
        three_fifths: 'offset-3-fifths',
        four_fifths: 'offset-4-fifths'
      }.each do |offset_name, offset_class|
        it "applies #{offset_class} for offset: :#{offset_name}" do
          render_inline(component) do |c|
            c.with_column(size: :one_quarter, offset: offset_name) { "Offset #{offset_name}" }
          end

          expect(page).to have_css "div.column.#{offset_class}"
        end
      end
    end
  end

  describe 'custom classes passthrough' do
    it 'accepts custom classes on container' do
      render_inline(described_class.new(class: 'custom-container')) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.columns.custom-container'
    end

    it 'accepts custom classes on column' do
      render_inline(component) do |c|
        c.with_column(class: 'custom-column') { 'Content' }
      end

      expect(page).to have_css 'div.column.custom-column'
    end

    it 'accepts data attributes on container' do
      render_inline(described_class.new(data: { testid: 'columns' })) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.columns[data-testid="columns"]'
    end

    it 'accepts data attributes on column' do
      render_inline(component) do |c|
        c.with_column(data: { testid: 'column' }) { 'Content' }
      end

      expect(page).to have_css 'div.column[data-testid="column"]'
    end
  end

  describe 'real-world layouts' do
    it 'renders two half columns correctly' do
      render_inline(component) do |c|
        c.with_column(size: :half) { 'Left' }
        c.with_column(size: :half) { 'Right' }
      end

      expect(page).to have_css 'div.column.col-half', count: 2
    end

    it 'renders 4-8 split with col-4 and col-8' do
      render_inline(component) do |c|
        c.with_column(size: 4) { 'Sidebar' }
        c.with_column(size: 8) { 'Main' }
      end

      expect(page).to have_css 'div.column.col-4'
      expect(page).to have_css 'div.column.col-8'
    end

    it 'renders three equal columns' do
      render_inline(component) do |c|
        c.with_column(size: :one_third) { 'One' }
        c.with_column(size: :one_third) { 'Two' }
        c.with_column(size: :one_third) { 'Three' }
      end

      expect(page).to have_css 'div.column.col-third', count: 3
    end

    it 'renders centered half-width column' do
      render_inline(described_class.new(center: true)) do |c|
        c.with_column(size: :half) { 'Centered content' }
      end

      expect(page).to have_css 'div.columns.columns-center'
      expect(page).to have_css 'div.column.col-half'
    end
  end
end
