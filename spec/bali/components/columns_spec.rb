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

  describe 'gapless modifier (Bulma: is-gapless)' do
    it 'applies is-gapless class when gapless: true' do
      render_inline(described_class.new(gapless: true)) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.columns.is-gapless'
    end
  end

  describe 'variable gap sizes (Bulma: is-variable is-N)' do
    (0..8).each do |gap_size|
      it "applies is-variable and is-#{gap_size} for gap: #{gap_size}" do
        render_inline(described_class.new(gap: gap_size)) do |c|
          c.with_column { 'Content' }
        end

        expect(page).to have_css "div.columns.is-variable.is-#{gap_size}"
      end
    end
  end

  describe 'multiline modifier (Bulma: is-multiline)' do
    it 'applies is-multiline class when multiline: true' do
      render_inline(described_class.new(multiline: true)) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.columns.is-multiline'
    end
  end

  describe 'alignment modifiers' do
    it 'applies is-centered when centered: true (Bulma: is-centered)' do
      render_inline(described_class.new(centered: true)) do |c|
        c.with_column(size: :half) { 'Centered' }
      end

      expect(page).to have_css 'div.columns.is-centered'
    end

    it 'applies is-vcentered when vcentered: true (Bulma: is-vcentered)' do
      render_inline(described_class.new(vcentered: true)) do |c|
        c.with_column { 'VCentered' }
      end

      expect(page).to have_css 'div.columns.is-vcentered'
    end
  end

  describe 'mobile modifier (Bulma: is-mobile)' do
    it 'applies is-mobile when mobile: true' do
      render_inline(described_class.new(mobile: true)) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css 'div.columns.is-mobile'
    end
  end

  describe 'column sizes' do
    describe 'numeric sizes (Bulma: is-1 through is-12)' do
      (1..12).each do |size|
        it "applies is-#{size} for size: #{size}" do
          render_inline(component) do |c|
            c.with_column(size: size) { "Column #{size}" }
          end

          expect(page).to have_css "div.column.is-#{size}"
        end
      end
    end

    describe 'symbolic sizes (Bulma fractions)' do
      {
        full: 'is-full',
        half: 'is-half',
        one_third: 'is-one-third',
        third: 'is-one-third',
        two_thirds: 'is-two-thirds',
        one_quarter: 'is-one-quarter',
        quarter: 'is-one-quarter',
        three_quarters: 'is-three-quarters',
        one_fifth: 'is-one-fifth',
        two_fifths: 'is-two-fifths',
        three_fifths: 'is-three-fifths',
        four_fifths: 'is-four-fifths'
      }.each do |size_name, size_class|
        it "applies #{size_class} for size: :#{size_name}" do
          render_inline(component) do |c|
            c.with_column(size: size_name) { "#{size_name} column" }
          end

          expect(page).to have_css "div.column.#{size_class}"
        end
      end
    end

    describe 'narrow columns (Bulma: is-narrow)' do
      it 'applies is-narrow class when narrow: true' do
        render_inline(component) do |c|
          c.with_column(narrow: true) { 'Narrow' }
        end

        expect(page).to have_css 'div.column.is-narrow'
      end
    end
  end

  describe 'column offsets (Bulma: is-offset-*)' do
    describe 'numeric offsets' do
      (1..11).each do |offset|
        it "applies is-offset-#{offset} for offset: #{offset}" do
          render_inline(component) do |c|
            c.with_column(size: 6, offset: offset) { "Offset #{offset}" }
          end

          expect(page).to have_css "div.column.is-offset-#{offset}"
        end
      end
    end

    describe 'symbolic offsets' do
      {
        half: 'is-offset-half',
        one_third: 'is-offset-one-third',
        third: 'is-offset-one-third',
        two_thirds: 'is-offset-two-thirds',
        one_quarter: 'is-offset-one-quarter',
        quarter: 'is-offset-one-quarter',
        three_quarters: 'is-offset-three-quarters',
        one_fifth: 'is-offset-one-fifth',
        two_fifths: 'is-offset-two-fifths',
        three_fifths: 'is-offset-three-fifths',
        four_fifths: 'is-offset-four-fifths'
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

      expect(page).to have_css 'div.column.is-half', count: 2
    end

    it 'renders 4-8 split like Bulma is-4 and is-8' do
      render_inline(component) do |c|
        c.with_column(size: 4) { 'Sidebar' }
        c.with_column(size: 8) { 'Main' }
      end

      expect(page).to have_css 'div.column.is-4'
      expect(page).to have_css 'div.column.is-8'
    end

    it 'renders three equal columns' do
      render_inline(component) do |c|
        c.with_column(size: :one_third) { 'One' }
        c.with_column(size: :one_third) { 'Two' }
        c.with_column(size: :one_third) { 'Three' }
      end

      expect(page).to have_css 'div.column.is-one-third', count: 3
    end

    it 'renders centered half-width column' do
      render_inline(described_class.new(centered: true)) do |c|
        c.with_column(size: :half) { 'Centered content' }
      end

      expect(page).to have_css 'div.columns.is-centered'
      expect(page).to have_css 'div.column.is-half'
    end
  end
end
