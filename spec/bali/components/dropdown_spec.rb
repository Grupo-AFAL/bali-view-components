# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Dropdown::Component, type: :component do
  describe 'basic rendering' do
    before do
      render_inline(described_class.new) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item 1' }
        c.with_item(href: '#') { 'Item 2' }
      end
    end

    it 'renders dropdown container with DaisyUI classes' do
      expect(page).to have_css '.dropdown'
    end

    it 'renders trigger button' do
      expect(page).to have_css '.btn', text: 'Trigger'
    end

    it 'renders dropdown content with menu class' do
      expect(page).to have_css '.dropdown-content.menu'
    end

    it 'renders items in list format' do
      expect(page).to have_css 'li', count: 2
    end
  end

  describe 'alignments' do
    it 'defaults to right alignment with dropdown-end' do
      render_inline(described_class.new) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '.dropdown.dropdown-end'
    end

    it 'renders left alignment without position class' do
      render_inline(described_class.new(align: :left)) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '.dropdown'
      expect(page).not_to have_css '.dropdown-end'
    end

    it 'renders top alignment' do
      render_inline(described_class.new(align: :top)) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '.dropdown.dropdown-top'
    end

    it 'renders bottom_end alignment' do
      render_inline(described_class.new(align: :bottom_end)) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '.dropdown.dropdown-bottom.dropdown-end'
    end
  end

  describe 'hoverable' do
    it 'adds dropdown-hover class when hoverable' do
      render_inline(described_class.new(hoverable: true)) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '.dropdown.dropdown-hover'
    end

    it 'does not add controller when hoverable (CSS-only)' do
      render_inline(described_class.new(hoverable: true)) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).not_to have_css '[data-controller="dropdown"]'
    end
  end

  describe 'wide option' do
    it 'uses w-80 class for wide dropdowns' do
      render_inline(described_class.new(wide: true)) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '.dropdown-content.w-80'
    end

    it 'uses w-52 class for normal dropdowns' do
      render_inline(described_class.new(wide: false)) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '.dropdown-content.w-52'
    end
  end

  describe 'custom content' do
    it 'renders custom HTML content' do
      render_inline(described_class.new) do |c|
        c.with_trigger { 'Trigger' }
        c.tag.li { c.tag.span('Custom content', class: 'custom-class') }
      end

      expect(page).to have_css 'li span.custom-class', text: 'Custom content'
    end
  end

  describe 'trigger component' do
    it 'renders with tabindex for focus behavior' do
      render_inline(described_class.new) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '[tabindex="0"]', text: 'Trigger'
    end

    it 'renders with role button for accessibility' do
      render_inline(described_class.new) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '[role="button"]', text: 'Trigger'
    end

    it 'supports icon variant' do
      render_inline(described_class.new) do |c|
        c.with_trigger(variant: :icon) { 'Icon' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '.btn.btn-ghost.btn-circle', text: 'Icon'
    end

    it 'supports ghost variant' do
      render_inline(described_class.new) do |c|
        c.with_trigger(variant: :ghost) { 'Ghost' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '.btn.btn-ghost', text: 'Ghost'
    end

    it 'supports custom variant with no btn class' do
      render_inline(described_class.new) do |c|
        c.with_trigger(variant: :custom, class: 'my-custom-class') { 'Custom' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '.my-custom-class', text: 'Custom'
      expect(page).not_to have_css '.btn', text: 'Custom'
    end
  end

  describe 'accessibility' do
    it 'renders menu with aria-label' do
      render_inline(described_class.new) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css 'ul[role="menu"][aria-label="Dropdown menu"]'
    end

    it 'renders items with proper roles' do
      render_inline(described_class.new) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item 1' }
        c.with_item(href: '#') { 'Item 2' }
      end

      expect(page).to have_css 'li[role="none"]', count: 2
      expect(page).to have_css 'a[role="menuitem"]', count: 2
    end

    it 'renders trigger with aria-haspopup and aria-expanded' do
      render_inline(described_class.new) do |c|
        c.with_trigger { 'Trigger' }
        c.with_item(href: '#') { 'Item' }
      end

      expect(page).to have_css '[aria-haspopup="true"][aria-expanded="false"]', text: 'Trigger'
    end
  end
end
