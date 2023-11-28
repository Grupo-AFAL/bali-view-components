# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::BulkActions::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::BulkActions::Component.new(**options) }

  context 'default' do
    it 'renders bulk actions component' do
      render_inline(component)

      expect(page).to have_css 'div.bulk-actions-component'
    end
  end

  context 'with actions' do
    it 'renders bulk actions component' do
      render_inline(component) do |c|
        c.action(name: 'Update', href: '#')
      end

      expect(page).to have_css 'div.bulk-actions-component'
      expect(page).to have_css 'div.actions-container'
      expect(page).to have_css 'div.floated-bar'
      expect(page).to have_css 'div.selected-count'
      expect(page).to have_css 'div.bulk-actions'
      expect(page).to have_css '[data-bulk-actions-target="bulkAction"]', visible: false
    end
  end

  context 'with items' do
    it 'renders bulk actions component' do
      render_inline(component) do |c|
        c.item(record_id: 1) { '<p>Item</p>'.html_safe }
      end

      expect(page).to have_css 'div.bulk-actions-component'
      expect(page).to have_css 'div.bulk-actions-component--item', text: 'Item'
      expect(page).to have_css '[data-record-id="1"]'
      expect(page).to have_css '[data-bulk-actions-target="item"]'
    end
  end
end
