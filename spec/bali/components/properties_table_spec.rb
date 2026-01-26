# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::PropertiesTable::Component, type: :component do
  describe 'basic rendering' do
    it 'renders the properties table component' do
      render_inline(described_class.new) do |c|
        c.with_property(label: 'Label 1', value: 'Value 1')
      end

      expect(page).to have_css 'table.properties-table-component'
      expect(page).to have_css 'th.property-label', text: 'Label 1'
      expect(page).to have_css 'td.property-value', text: 'Value 1'
    end

    it 'renders multiple properties' do
      render_inline(described_class.new) do |c|
        c.with_property(label: 'Name', value: 'John')
        c.with_property(label: 'Email', value: 'john@example.com')
        c.with_property(label: 'Phone', value: '555-1234')
      end

      expect(page).to have_css 'tr.properties-table-property-component', count: 3
      expect(page).to have_css 'th.property-label', text: 'Name'
      expect(page).to have_css 'td.property-value', text: 'john@example.com'
    end

    it 'renders tbody wrapper for semantic HTML' do
      render_inline(described_class.new) do |c|
        c.with_property(label: 'Test', value: 'Value')
      end

      expect(page).to have_css 'table > tbody > tr'
    end
  end

  describe 'property content' do
    it 'accepts content block instead of value param' do
      render_inline(described_class.new) do |c|
        c.with_property(label: 'Status') do
          'Active'
        end
      end

      expect(page).to have_css 'td.property-value', text: 'Active'
    end

    it 'prefers value param over content block' do
      render_inline(described_class.new) do |c|
        c.with_property(label: 'Status', value: 'Preferred') do
          'Ignored'
        end
      end

      expect(page).to have_css 'td.property-value', text: 'Preferred'
      expect(page).to have_no_text 'Ignored'
    end
  end

  describe 'CSS classes' do
    it 'applies DaisyUI table classes with zebra striping' do
      render_inline(described_class.new) do |c|
        c.with_property(label: 'Test', value: 'Value')
      end

      expect(page).to have_css 'table.table'
      expect(page).to have_css 'table.table-zebra'
      expect(page).to have_css 'table.properties-table-component'
    end

    it 'uses th for label cells with scope="row"' do
      render_inline(described_class.new) do |c|
        c.with_property(label: 'Test', value: 'Value')
      end

      expect(page).to have_css 'th.property-label[scope="row"]'
    end

    it 'applies property row classes' do
      render_inline(described_class.new) do |c|
        c.with_property(label: 'Test', value: 'Value')
      end

      expect(page).to have_css 'tr.properties-table-property-component'
    end
  end

  describe 'options passthrough' do
    it 'passes custom options to table element' do
      render_inline(described_class.new(id: 'my-table', data: { testid: 'props-table' })) do |c|
        c.with_property(label: 'Test', value: 'Value')
      end

      expect(page).to have_css 'table#my-table'
      expect(page).to have_css 'table[data-testid="props-table"]'
    end

    it 'merges custom classes with component classes' do
      render_inline(described_class.new(class: 'custom-table')) do |c|
        c.with_property(label: 'Test', value: 'Value')
      end

      expect(page).to have_css 'table.properties-table-component.custom-table'
    end

    it 'passes custom options to property rows' do
      render_inline(described_class.new) do |c|
        c.with_property(label: 'Test', value: 'Value', id: 'row-1', data: { row: 'first' })
      end

      expect(page).to have_css 'tr#row-1'
      expect(page).to have_css 'tr[data-row="first"]'
    end

    it 'merges custom classes with property row classes' do
      render_inline(described_class.new) do |c|
        c.with_property(label: 'Test', value: 'Value', class: 'highlight')
      end

      expect(page).to have_css 'tr.properties-table-property-component.highlight'
    end
  end

  describe 'empty state' do
    it 'renders empty table when no properties provided' do
      render_inline(described_class.new)

      expect(page).to have_css 'table.properties-table-component'
      expect(page).to have_css 'tbody'
      expect(page).to have_no_css 'tr'
    end
  end
end
