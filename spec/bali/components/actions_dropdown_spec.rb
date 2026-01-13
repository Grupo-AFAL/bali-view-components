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

    it 'supports position end' do
      render_inline(described_class.new(position: :end)) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'div.dropdown.dropdown-end'
      expect(page).not_to have_css 'div.dropdown-start'
    end
  end
end
