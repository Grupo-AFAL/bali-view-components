# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::ActionsDropdown::Component, type: :component do
  describe 'basic rendering' do
    it 'renders dropdown component with DaisyUI classes' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-start'
    end

    it 'renders with DaisyUI btn classes on trigger' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css '.btn.btn-ghost.btn-sm.btn-circle'
    end

    it 'renders dropdown-content menu' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'ul.dropdown-content.menu'
      expect(page).to have_css 'ul.dropdown-content li a', text: 'Edit'
    end

    it 'renders items inside li elements' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#edit')
        c.with_item(name: 'Delete', href: '#delete', method: :delete)
      end

      expect(page).to have_css 'ul.menu li', count: 2
    end
  end

  describe 'horizontal alignment' do
    it 'supports align start (default)' do
      render_inline(described_class.new(align: :start)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-start'
    end

    it 'supports align center' do
      render_inline(described_class.new(align: :center)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-center'
    end

    it 'supports align end' do
      render_inline(described_class.new(align: :end)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-end'
    end
  end

  describe 'vertical direction' do
    it 'supports direction top' do
      render_inline(described_class.new(direction: :top)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-top'
    end

    it 'supports direction bottom' do
      render_inline(described_class.new(direction: :bottom)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-bottom'
    end

    it 'supports direction left' do
      render_inline(described_class.new(direction: :left)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-left'
    end

    it 'supports direction right' do
      render_inline(described_class.new(direction: :right)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-right'
    end
  end

  describe 'combined positions' do
    it 'supports direction and alignment together' do
      render_inline(described_class.new(direction: :top, align: :end)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-top.dropdown-end'
    end
  end
end
