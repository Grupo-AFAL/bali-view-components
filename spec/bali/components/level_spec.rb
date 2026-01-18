# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Level::Component, type: :component do
  let(:component) { Bali::Level::Component.new }

  it 'renders' do
    render_inline(component) do |c|
      c.with_left do |level|
        level.with_item(text: 'Left')
      end

      c.with_right do |level|
        level.with_item(text: 'Right')
      end
    end

    expect(page).to have_css '.level div'
    expect(page).to have_css 'div.level-item', text: 'Left'
    expect(page).to have_css 'div.level-item', text: 'Right'
  end

  context 'with level items' do
    it 'renders' do
      render_inline(component) do |c|
        c.with_item(text: 'Item 1')

        c.with_item { '<h1>Item 2</h1>'.html_safe }
      end

      expect(page).to have_css '.level div'
      expect(page).to have_css 'div.level-item', text: 'Item 1'
      expect(page).to have_css 'div.level-item', text: 'Item 2'
    end
  end

  describe 'alignments' do
    it 'applies start alignment' do
      render_inline(described_class.new(align: :start)) do |c|
        c.with_left { 'Left content' }
      end

      expect(page).to have_css('.level.items-start')
    end

    it 'applies center alignment by default' do
      render_inline(described_class.new) do |c|
        c.with_left { 'Left content' }
      end

      expect(page).to have_css('.level.items-center')
    end

    it 'applies end alignment' do
      render_inline(described_class.new(align: :end)) do |c|
        c.with_left { 'Left content' }
      end

      expect(page).to have_css('.level.items-end')
    end

    it 'defaults to center alignment for invalid values' do
      render_inline(described_class.new(align: :invalid)) do |c|
        c.with_left { 'Left content' }
      end

      expect(page).to have_css('.level.items-center')
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(class: 'custom-class')) do |c|
        c.with_item(text: 'Item')
      end

      expect(page).to have_css('.level.custom-class')
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(data: { testid: 'level-test' })) do |c|
        c.with_item(text: 'Item')
      end

      expect(page).to have_css('[data-testid="level-test"]')
    end
  end

  describe 'Side::Component' do
    it 'renders left side with items' do
      render_inline(component) do |c|
        c.with_left do |side|
          side.with_item(text: 'Left 1')
          side.with_item(text: 'Left 2')
        end
      end

      expect(page).to have_css('.level-left')
      expect(page).to have_css('.level-item', text: 'Left 1')
      expect(page).to have_css('.level-item', text: 'Left 2')
    end

    it 'renders right side with items' do
      render_inline(component) do |c|
        c.with_right do |side|
          side.with_item(text: 'Right 1')
        end
      end

      expect(page).to have_css('.level-right')
      expect(page).to have_css('.level-item', text: 'Right 1')
    end

    it 'accepts custom classes on side' do
      render_inline(component) do |c|
        c.with_left(class: 'custom-side') do
          'Content'
        end
      end

      expect(page).to have_css('.level-left.custom-side')
    end
  end

  describe 'Item::Component' do
    it 'renders item with text param' do
      render_inline(component) do |c|
        c.with_item(text: 'Text param')
      end

      expect(page).to have_css('.level-item', text: 'Text param')
    end

    it 'renders item with block content' do
      render_inline(component) do |c|
        c.with_item { 'Block content' }
      end

      expect(page).to have_css('.level-item', text: 'Block content')
    end

    it 'accepts custom classes on item' do
      render_inline(component) do |c|
        c.with_item(text: 'Item', class: 'custom-item')
      end

      expect(page).to have_css('.level-item.custom-item')
    end
  end
end
