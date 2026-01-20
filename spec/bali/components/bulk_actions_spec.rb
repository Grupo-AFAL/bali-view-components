# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::BulkActions::Component, type: :component do
  let(:options) { {} }
  let(:component) { described_class.new(**options) }

  describe 'rendering' do
    it 'renders bulk actions component with base class' do
      render_inline(component)

      expect(page).to have_css 'div.bulk-actions-component'
    end

    it 'renders with Stimulus controller' do
      render_inline(component)

      expect(page).to have_css "[data-controller='bulk-actions']"
    end

    it 'accepts custom classes' do
      render_inline(described_class.new(class: 'custom-class'))

      expect(page).to have_css 'div.bulk-actions-component.custom-class'
    end
  end

  describe 'items' do
    it 'renders items with correct data attributes' do
      render_inline(component) do |c|
        c.with_item(record_id: 42) { 'Content' }
      end

      expect(page).to have_css "[data-record-id='42']"
      expect(page).to have_css "[data-bulk-actions-target='item']"
      expect(page).to have_css "[data-action='click->bulk-actions#toggle']"
    end

    it 'renders items with base class' do
      render_inline(component) do |c|
        c.with_item(record_id: 1) { 'Content' }
      end

      expect(page).to have_css '.bulk-actions-item', text: 'Content'
    end

    it 'accepts custom classes on items' do
      render_inline(component) do |c|
        c.with_item(record_id: 1, class: 'custom-item-class') { 'Content' }
      end

      expect(page).to have_css '.bulk-actions-item.custom-item-class'
    end

    it 'renders multiple items' do
      render_inline(component) do |c|
        c.with_item(record_id: 1) { 'Item 1' }
        c.with_item(record_id: 2) { 'Item 2' }
        c.with_item(record_id: 3) { 'Item 3' }
      end

      expect(page).to have_css '.bulk-actions-item', count: 3
      expect(page).to have_css "[data-record-id='1']"
      expect(page).to have_css "[data-record-id='2']"
      expect(page).to have_css "[data-record-id='3']"
    end
  end

  describe 'actions' do
    it 'renders actions container with Stimulus target' do
      render_inline(component) do |c|
        c.with_action(label: 'Update', href: '/update')
      end

      expect(page).to have_css "[data-bulk-actions-target='actionsContainer']"
    end

    it 'renders selected count with Stimulus target' do
      render_inline(component) do |c|
        c.with_action(label: 'Update', href: '/update')
      end

      expect(page).to have_css "[data-bulk-actions-target='selectedCount']", text: '0'
    end

    it 'hides actions container initially' do
      render_inline(component) do |c|
        c.with_action(label: 'Archive', href: '/archive')
      end

      expect(page).to have_css ".hidden[data-bulk-actions-target='actionsContainer']"
    end

    context 'with POST method (default)' do
      it 'renders as a form' do
        render_inline(component) do |c|
          c.with_action(label: 'Delete', href: '/delete')
        end

        expect(page).to have_css "form[action='/delete']"
        expect(page).to have_button 'Delete'
        expect(page).to have_css "input[name='selected_ids'][data-bulk-actions-target='bulkAction']",
                                 visible: false
      end

      it 'applies variant classes to submit button' do
        render_inline(component) do |c|
          c.with_action(label: 'Delete', href: '/delete', variant: :error)
        end

        expect(page).to have_css 'input.btn.btn-sm.btn-error'
      end
    end

    context 'with DELETE method' do
      it 'renders as a form with hidden method field' do
        render_inline(component) do |c|
          c.with_action(label: 'Remove', href: '/remove', method: :delete)
        end

        expect(page).to have_css "form[action='/remove']"
        expect(page).to have_css "input[name='_method'][value='delete']", visible: false
        expect(page).to have_button 'Remove'
      end
    end

    context 'with GET method' do
      it 'renders as a link' do
        render_inline(component) do |c|
          c.with_action(label: 'Export', href: '/export', method: :get)
        end

        expect(page).to have_link 'Export', href: '/export'
        expect(page).to have_css "a[data-bulk-actions-target='bulkAction']"
      end

      it 'applies button styling to link' do
        render_inline(component) do |c|
          c.with_action(label: 'Export', href: '/export', method: :get, variant: :info)
        end

        expect(page).to have_css 'a.btn.btn-info'
      end
    end

    it 'renders multiple actions' do
      render_inline(component) do |c|
        c.with_action(label: 'Archive', href: '/archive', variant: :info)
        c.with_action(label: 'Delete', href: '/delete', variant: :error)
      end

      expect(page).to have_button 'Archive'
      expect(page).to have_button 'Delete'
    end
  end

  describe 'combined items and actions' do
    it 'renders both items and actions together' do
      render_inline(component) do |c|
        c.with_action(label: 'Bulk Update', href: '/bulk_update')
        c.with_item(record_id: 1) { 'Item 1' }
        c.with_item(record_id: 2) { 'Item 2' }
      end

      expect(page).to have_css '.bulk-actions-component'
      expect(page).to have_css '.bulk-actions-item', count: 2
      expect(page).to have_button 'Bulk Update'
    end
  end
end
