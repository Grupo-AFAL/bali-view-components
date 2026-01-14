# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Columns::Component, type: :component do
  let(:component) { Bali::Columns::Component.new }

  describe 'basic rendering' do
    it 'renders container with flex classes' do
      render_inline(component) do |c|
        c.with_column { 'First' }
        c.with_column { 'Second' }
      end

      expect(page).to have_css '.columns-component.flex.flex-wrap.gap-4'
    end

    it 'renders columns with default flex-1 sizing to fill remaining space' do
      render_inline(component) do |c|
        c.with_column { 'First' }
        c.with_column { 'Second' }
      end

      expect(page).to have_css 'div.column.flex-1', count: 2
    end
  end

  describe 'column sizes' do
    Bali::Columns::Column::Component::SIZES.each do |size_name, size_class|
      it "applies #{size_name} size with #{size_class}" do
        render_inline(component) do |c|
          c.with_column(size: size_name) { "#{size_name} column" }
        end

        column = page.find('div.column')
        expect(column[:class]).to include(size_class)
      end
    end
  end

  describe 'column offsets' do
    Bali::Columns::Column::Component::OFFSETS.each do |offset_name, offset_class|
      it "applies #{offset_name} offset with #{offset_class}" do
        render_inline(component) do |c|
          c.with_column(offset: offset_name) { "#{offset_name} offset" }
        end

        column = page.find('div.column')
        expect(column[:class]).to include(offset_class)
      end
    end
  end

  describe 'combined size and offset' do
    it 'applies both size and offset' do
      render_inline(component) do |c|
        c.with_column(size: :half, offset: :quarter) { 'Combined' }
      end

      column = page.find('div.column')
      expect(column[:class]).to include('w-[calc(50%-0.5rem)]')
      expect(column[:class]).to include('ml-[25%]')
    end
  end

  describe 'custom classes passthrough' do
    it 'accepts custom classes on container' do
      render_inline(Bali::Columns::Component.new(class: 'custom-container')) do |c|
        c.with_column { 'Content' }
      end

      expect(page).to have_css '.columns-component.custom-container'
    end

    it 'accepts custom classes on column' do
      render_inline(component) do |c|
        c.with_column(class: 'custom-column') { 'Content' }
      end

      expect(page).to have_css 'div.column.custom-column'
    end
  end
end
