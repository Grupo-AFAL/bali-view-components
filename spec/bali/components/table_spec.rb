# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Table::Component, type: :component do
  let(:component) { Bali::Table::Component.new(**@options) }

  before { @options = {} }

  describe 'constants' do
    it 'defines TABLE_CLASSES' do
      expect(described_class::TABLE_CLASSES).to eq('table table-zebra w-full')
    end

    it 'defines CONTAINER_CLASSES' do
      expect(described_class::CONTAINER_CLASSES).to eq('overflow-x-auto table-component')
    end

    it 'defines STICKY_CLASSES' do
      expect(described_class::STICKY_CLASSES).to include('overflow-visible')
    end
  end

  describe 'headers' do
    it 'renders a table with headers using array syntax' do
      render_inline(component) do |c|
        c.with_headers([
                         { name: 'name' },
                         { name: 'amount' }
                       ])
      end

      expect(page).to have_css 'table'
      expect(page).to have_css 'tr th', text: 'name'
      expect(page).to have_css 'tr th', text: 'amount'
    end

    it 'renders a table with headers using singular syntax' do
      render_inline(component) do |c|
        c.with_header(name: 'name')
        c.with_header(name: 'amount', class: 'text-right')
      end

      expect(page).to have_css 'table'
      expect(page).to have_css 'tr th', text: 'name'
      expect(page).to have_css 'tr th.text-right', text: 'amount'
    end

    it 'excludes hidden headers from rendering' do
      render_inline(component) do |c|
        c.with_header(name: 'visible')
        c.with_header(name: 'hidden', hidden: true)
      end

      expect(page).to have_css 'tr th', text: 'visible'
      expect(page).not_to have_css 'tr th', text: 'hidden'
    end
  end

  describe 'rows' do
    it 'renders a table with rows' do
      render_inline(component) do |c|
        c.with_row { '<td>Hola</td>'.html_safe }
      end

      expect(page).to have_css 'tr td', text: 'Hola'
    end
  end

  describe 'footer' do
    it 'renders a table with footer' do
      render_inline(component) do |c|
        c.with_footer { '<td>Total</td>'.html_safe }
      end

      expect(page).to have_css 'table'
      expect(page).to have_css 'tfoot tr td', text: 'Total'
    end
  end

  describe 'empty states' do
    it 'renders no results message when filters are active' do
      form = double('form')
      allow(form).to receive(:active_filters?) { true }
      allow(form).to receive(:id) { '1' }

      @options = { form: form }
      render_inline(component)

      expect(page).to have_css '.empty-table p', text: 'No Results'
    end

    it 'renders no records message when no filters' do
      @options.merge!(form: @filter_form)
      render_inline(component)

      expect(page).to have_css '.empty-table p', text: 'No Records'
    end

    it 'renders a table with new record link' do
      render_inline(component) do |c|
        c.with_new_record_link(name: 'Add New Record', href: '#', modal: false)
      end

      expect(page).to have_css 'a', text: 'Add New Record'
    end

    context 'with custom no records notification' do
      it 'renders custom message' do
        @options.merge!(form: @filter_form)
        render_inline(component) do |c|
          c.with_no_records_notification { 'So sorry, no records found!' }
        end

        expect(page).to have_css '.empty-table', text: 'So sorry, no records found!'
      end
    end

    context 'with custom no results notification' do
      it 'renders custom message when filters active' do
        form = double('form')
        allow(form).to receive(:active_filters?) { true }
        allow(form).to receive(:id) { '1' }

        @options = { form: form }
        render_inline(component) do |c|
          c.with_no_results_notification { 'So sorry, no results!' }
        end

        expect(page).to have_css '.empty-table', text: 'So sorry, no results!'
      end
    end
  end

  describe 'bulk actions' do
    it 'renders checkboxes when bulk_actions provided' do
      @options = { bulk_actions: [{ name: 'Delete', href: '/delete' }] }
      render_inline(component) do |c|
        c.with_header(name: 'Name')
        c.with_row(record_id: 1) { '<td>Row 1</td>'.html_safe }
      end

      expect(page).to have_css 'input[type="checkbox"][data-table-target="toggleAll"]'
      expect(page).to have_css 'input[type="checkbox"][data-table-target="checkbox"]'
    end

    it 'renders bulk actions container' do
      @options = { bulk_actions: [{ name: 'Delete', href: '/delete' }] }
      render_inline(component) do |c|
        c.with_header(name: 'Name')
      end

      expect(page).to have_css '.bulk-actions-container'
      expect(page).to have_css '[data-table-target="actionsContainer"]'
    end

    it 'renders bulk action buttons' do
      @options = { bulk_actions: [{ name: 'Delete Selected', href: '/bulk_delete' }] }
      render_inline(component) do |c|
        c.with_header(name: 'Name')
      end

      expect(page).to have_css 'input[type="submit"][value="Delete Selected"]'
    end

    it 'does not render checkboxes without bulk_actions' do
      render_inline(component) do |c|
        c.with_header(name: 'Name')
        c.with_row { '<td>Row 1</td>'.html_safe }
      end

      expect(page).not_to have_css 'input[type="checkbox"][data-table-target="toggleAll"]'
    end
  end

  describe 'sticky headers' do
    it 'applies sticky classes when enabled' do
      @options = { sticky_headers: true }
      render_inline(component) do |c|
        c.with_header(name: 'Name')
      end

      expect(page).to have_css '.overflow-visible'
    end

    it 'does not apply sticky classes by default' do
      render_inline(component) do |c|
        c.with_header(name: 'Name')
      end

      expect(page).not_to have_css '.overflow-visible'
    end
  end

  describe 'DaisyUI classes' do
    it 'applies table and table-zebra classes' do
      render_inline(component) do |c|
        c.with_header(name: 'Name')
      end

      expect(page).to have_css 'table.table.table-zebra'
    end

    it 'wraps table in container with overflow classes' do
      render_inline(component) do |c|
        c.with_header(name: 'Name')
      end

      expect(page).to have_css '.overflow-x-auto.table-component'
    end
  end

  describe 'options passthrough' do
    it 'accepts custom id' do
      @options = { id: 'my-table' }
      render_inline(component)

      expect(page).to have_css '#my-table'
    end

    it 'accepts custom classes' do
      @options = { class: 'custom-class' }
      render_inline(component)

      expect(page).to have_css 'table.custom-class'
    end

    it 'accepts tbody options' do
      @options = { tbody: { class: 'custom-tbody' } }
      render_inline(component)

      expect(page).to have_css 'tbody.custom-tbody'
    end

    it 'accepts table_container options' do
      @options = { table_container: { class: 'custom-container' } }
      render_inline(component)

      expect(page).to have_css 'div.custom-container'
    end
  end

  describe '#container_id' do
    it 'returns custom id when provided' do
      component = described_class.new(id: 'custom-id')
      expect(component.container_id).to eq('custom-id')
    end

    it 'returns form id when no custom id' do
      form = double('form', id: 'form-123')
      component = described_class.new(form: form)
      expect(component.container_id).to eq('form-123')
    end

    it 'returns nil when no id or form' do
      component = described_class.new
      expect(component.container_id).to be_nil
    end
  end

  describe '#bulk_actions?' do
    it 'returns true when bulk_actions provided' do
      component = described_class.new(bulk_actions: [{ name: 'Delete', href: '/delete' }])
      expect(component.bulk_actions?).to be true
    end

    it 'returns false when no bulk_actions' do
      component = described_class.new
      expect(component.bulk_actions?).to be false
    end
  end
end
