# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::ActionsDropdown::Component, type: :component do
  describe 'basic rendering' do
    it 'renders actions-dropdown component' do
      render_inline(described_class.new) do |c|
        c.tag.span('test')
      end

      expect(page).to have_css 'div.actions-dropdown'
    end

    it 'renders with DaisyUI btn classes on trigger' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css '.btn.btn-ghost.btn-circle'
    end

    it 'renders template for hovercard content' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Edit', href: '#')
      end

      expect(page).to have_css 'template[data-hovercard-target="template"]', visible: false
    end
  end
end
