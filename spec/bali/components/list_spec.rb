# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::List::Component, type: :component do
  describe 'rendering' do
    it 'renders with DaisyUI list class' do
      render_inline(described_class.new) do |c|
        c.with_item do |i|
          i.with_title('Item 1')
        end
      end

      expect(page).to have_css('ul.list[role="list"]')
      expect(page).to have_css('li.list-row')
    end

    it 'renders list item with text arguments' do
      render_inline(described_class.new) do |c|
        c.with_item do |i|
          i.with_title('Item 1')
          i.with_subtitle('Subtitle 1')
        end
      end

      expect(page).to have_css('.font-semibold', text: 'Item 1')
      expect(page).to have_css('.text-sm', text: 'Subtitle 1')
    end

    it 'renders list item with block arguments' do
      render_inline(described_class.new) do |c|
        c.with_item do |i|
          i.with_title { 'Item 1' }
          i.with_subtitle { 'Subtitle 1' }
        end
      end

      expect(page).to have_css('.font-semibold', text: 'Item 1')
      expect(page).to have_css('.text-sm', text: 'Subtitle 1')
    end

    it 'renders list item actions' do
      render_inline(described_class.new) do |c|
        c.with_item do |i|
          i.with_action do
            c.tag.a('Link 1', href: '/link-1')
          end
        end
      end

      expect(page).to have_css('a[href="/link-1"]', text: 'Link 1')
    end
  end

  describe 'borderless option' do
    it 'renders with border by default' do
      render_inline(described_class.new) do |c|
        c.with_item { |i| i.with_title('Item') }
      end

      expect(page).to have_css('ul.list.border.border-base-300')
    end

    it 'removes border when borderless: true' do
      render_inline(described_class.new(borderless: true)) do |c|
        c.with_item { |i| i.with_title('Item') }
      end

      expect(page).to have_css('ul.list')
      expect(page).to have_no_css('ul.border')
    end
  end

  describe 'relaxed_spacing option' do
    it 'applies relaxed spacing class' do
      render_inline(described_class.new(relaxed_spacing: true)) do |c|
        c.with_item { |i| i.with_title('Item') }
      end

      expect(page).to have_css('ul[class*="py-4"]')
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(class: 'custom-list')) do |c|
        c.with_item { |i| i.with_title('Item') }
      end

      expect(page).to have_css('ul.list.custom-list')
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(data: { testid: 'my-list' })) do |c|
        c.with_item { |i| i.with_title('Item') }
      end

      expect(page).to have_css('ul[data-testid="my-list"]')
    end
  end

  describe 'item options passthrough' do
    it 'accepts custom classes on items' do
      render_inline(described_class.new) do |c|
        c.with_item(class: 'highlighted') do |i|
          i.with_title('Item')
        end
      end

      expect(page).to have_css('li.list-row.highlighted')
    end

    it 'accepts data attributes on items' do
      render_inline(described_class.new) do |c|
        c.with_item(data: { item: 'first' }) do |i|
          i.with_title('Item')
        end
      end

      expect(page).to have_css('li[data-item="first"]')
    end
  end

  describe 'title and subtitle options' do
    it 'accepts custom classes on title' do
      render_inline(described_class.new) do |c|
        c.with_item do |i|
          i.with_title('Custom Title', class: 'text-primary')
        end
      end

      expect(page).to have_css('span.font-semibold.text-primary', text: 'Custom Title')
    end

    it 'accepts custom classes on subtitle' do
      render_inline(described_class.new) do |c|
        c.with_item do |i|
          i.with_subtitle('Custom Subtitle', class: 'text-info')
        end
      end

      expect(page).to have_css('span.text-sm.text-info', text: 'Custom Subtitle')
    end
  end

  describe 'content slot' do
    it 'renders additional content' do
      render_inline(described_class.new) do |c|
        c.with_item do |i|
          i.with_title('Item')
          'Additional content'
        end
      end

      expect(page).to have_text('Additional content')
      expect(page).to have_css('.list-col-grow')
    end
  end

  describe 'constants' do
    it 'has BASE_CLASSES constant' do
      expect(described_class::BASE_CLASSES).to eq('list')
    end

    it 'has BORDERED_CLASSES constant' do
      expect(described_class::BORDERED_CLASSES).to eq('border border-base-300 rounded-box')
    end
  end

  describe 'item constants' do
    it 'has BASE_CLASSES constant' do
      expect(Bali::List::Item::Component::BASE_CLASSES).to eq('list-row')
    end

    it 'has TITLE_CLASSES constant' do
      expect(Bali::List::Item::Component::TITLE_CLASSES).to eq('font-semibold')
    end

    it 'has SUBTITLE_CLASSES constant' do
      expect(Bali::List::Item::Component::SUBTITLE_CLASSES).to eq('text-sm text-base-content/60')
    end
  end
end
