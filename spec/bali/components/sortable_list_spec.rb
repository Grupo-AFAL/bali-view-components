# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::SortableList::Component, type: :component do
  describe 'BASE_CLASSES constant' do
    it 'is frozen' do
      expect(described_class::BASE_CLASSES).to be_frozen
    end

    it 'contains expected classes' do
      expect(described_class::BASE_CLASSES).to include('sortable-list-component')
      expect(described_class::BASE_CLASSES).to include('p-0')
    end
  end

  describe 'DEFAULTS constant' do
    it 'is frozen' do
      expect(described_class::DEFAULTS).to be_frozen
    end

    it 'contains default values' do
      expect(described_class::DEFAULTS[:position_param_name]).to eq('position')
      expect(described_class::DEFAULTS[:list_param_name]).to eq('list_id')
      expect(described_class::DEFAULTS[:response_kind]).to eq(:html)
      expect(described_class::DEFAULTS[:disabled]).to be(false)
      expect(described_class::DEFAULTS[:animation]).to eq(150)
    end
  end

  describe 'rendering' do
    it 'renders a sortable component with base classes' do
      render_inline(described_class.new)

      expect(page).to have_css('div.sortable-list-component')
      expect(page).to have_css('div[data-controller="sortable-list"]')
      expect(page).to have_css('div[data-sortable-list-disabled-value="false"]')
    end

    it 'renders with content block' do
      render_inline(described_class.new) { 'Custom content' }

      expect(page).to have_text('Custom content')
    end
  end

  describe 'disabled option' do
    it 'renders disabled sortable component' do
      render_inline(described_class.new(disabled: true))

      expect(page).to have_css('div[data-sortable-list-disabled-value="true"]')
    end

    it 'renders enabled by default' do
      render_inline(described_class.new)

      expect(page).to have_css('div[data-sortable-list-disabled-value="false"]')
    end
  end

  describe 'items slot' do
    it 'renders sortable component with items' do
      render_inline(described_class.new) do |c|
        c.with_item(update_url: '/items/1') { 'Item 1' }
        c.with_item(update_url: '/items/2') { 'Item 2' }
        c.with_item(update_url: '/items/3', item_pull: false) { 'Item 3' }
      end

      expect(page).to have_css('div.sortable-item', count: 3)
      expect(page).to have_css('div.sortable-item[data-sortable-update-url="/items/1"]')
      expect(page).to have_css('div.sortable-item[data-sortable-update-url="/items/2"]')
      expect(page).to have_css('div.sortable-item[data-sortable-update-url="/items/3"]')
      expect(page).to have_css('div.sortable-item[data-sortable-item-pull="true"]', count: 2)
      expect(page).to have_css('div.sortable-item[data-sortable-item-pull="false"]', count: 1)
    end
  end

  describe 'all Stimulus values' do
    let(:options) do
      {
        animation: 200,
        disabled: true,
        group_name: 'group_test_name',
        handle: '.handle',
        list_id: 10,
        list_param_name: 'custom_list_id',
        resource_name: 'tasks',
        response_kind: :turbo_stream,
        position_param_name: 'custom_position'
      }
    end

    it 'passes all values to Stimulus controller' do
      render_inline(described_class.new(**options))

      expect(page).to have_css('div[data-sortable-list-animation-value="200"]')
      expect(page).to have_css('div[data-sortable-list-disabled-value="true"]')
      expect(page).to have_css('div[data-sortable-list-group-name-value="group_test_name"]')
      expect(page).to have_css('div[data-sortable-list-handle-value=".handle"]')
      expect(page).to have_css('div[data-sortable-list-list-id-value="10"]')
      expect(page).to have_css('div[data-sortable-list-list-param-name-value="custom_list_id"]')
      expect(page).to have_css('div[data-sortable-list-resource-name-value="tasks"]')
      expect(page).to have_css('div[data-sortable-list-response-kind-value="turbo_stream"]')
      expect(page).to have_css('div[data-sortable-list-position-param-name-value="custom_position"]')
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(class: 'custom-class'))

      expect(page).to have_css('div.sortable-list-component.custom-class')
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(data: { testid: 'sortable-test' }))

      expect(page).to have_css('div[data-testid="sortable-test"]')
    end

    it 'accepts id attribute' do
      render_inline(described_class.new(id: 'my-sortable'))

      expect(page).to have_css('div#my-sortable')
    end
  end

  describe 'cursor styling' do
    it 'adds cursor-grab to items when no handle is specified' do
      render_inline(described_class.new) do |c|
        c.with_item(update_url: '/items/1') { 'Item 1' }
      end

      # Parent should have the CSS class that targets items
      expect(page).to have_css('div[class*="[&_.sortable-item]:cursor-grab"]')
    end

    it 'does not add cursor-grab to items when handle is specified' do
      render_inline(described_class.new(handle: '.handle')) do |c|
        c.with_item(update_url: '/items/1') { 'Item 1' }
      end

      # Parent should NOT have the item cursor class
      expect(page).not_to have_css('div[class*="[&_.sortable-item]:cursor-grab"]')
      # But should still have the handle cursor class
      expect(page).to have_css('div[class*="[&_.handle]:cursor-grab"]')
    end
  end
end

RSpec.describe Bali::SortableList::Item::Component, type: :component do
  describe 'BASE_CLASSES constant' do
    it 'is frozen' do
      expect(described_class::BASE_CLASSES).to be_frozen
    end

    it 'contains expected classes' do
      expect(described_class::BASE_CLASSES).to include('sortable-item')
      expect(described_class::BASE_CLASSES).to include('bg-base-100')
      expect(described_class::BASE_CLASSES).to include('border')
    end
  end

  describe 'rendering' do
    it 'renders an item with update_url' do
      render_inline(described_class.new(update_url: '/items/1')) { 'Item content' }

      expect(page).to have_css('div.sortable-item')
      expect(page).to have_css('div[data-sortable-update-url="/items/1"]')
      expect(page).to have_text('Item content')
    end

    it 'sets item_pull to true by default' do
      render_inline(described_class.new(update_url: '/items/1'))

      expect(page).to have_css('div[data-sortable-item-pull="true"]')
    end

    it 'allows disabling item_pull' do
      render_inline(described_class.new(update_url: '/items/1', item_pull: false))

      expect(page).to have_css('div[data-sortable-item-pull="false"]')
    end
  end

  describe 'nested list slot' do
    it 'renders with nested sortable list' do
      render_inline(described_class.new(update_url: '/items/1')) do |item|
        item.with_list(list_id: 'nested') do |nested|
          nested.with_item(update_url: '/items/nested/1') { 'Nested item' }
        end
        'Parent item'
      end

      expect(page).to have_css('div.sortable-item div.sortable-list-component')
      expect(page).to have_text('Parent item')
      expect(page).to have_text('Nested item')
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(update_url: '/items/1', class: 'custom-item'))

      expect(page).to have_css('div.sortable-item.custom-item')
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(update_url: '/items/1', data: { testid: 'item-test' }))

      expect(page).to have_css('div[data-testid="item-test"]')
    end
  end
end
