# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::SortableList::Component, type: :component do
  before { @options = {} }
  let(:component) { Bali::SortableList::Component.new(**@options) }

  it 'renders a sortable component' do
    render_inline(component)
    expect(page).to have_css 'div.sortable-list-component'
    expect(page).to have_css 'div[data-controller="sortable-list"]'
    expect(page).to have_css 'div[data-sortable-list-disabled-value="false"]'
  end

  it 'renders disabled sortable component' do
    @options[:disabled] = true
    render_inline(component)
    expect(page).to have_css 'div[data-sortable-list-disabled-value="true"]'
  end

  it 'renders sortable component with items' do
    render_inline(component) do |c|
      c.item(update_url: '/') { 'Item 1' }
      c.item(update_url: '/') { 'Item 2' }
      c.item(update_url: '/', item_pull: false) { 'Item 3' }
    end

    expect(page).to have_css 'div.sortable-item', count: 3
    expect(page).to(
      have_css('div.sortable-item[data-sortable-update-url="/"]', count: 3)
    )
    expect(page).to(
      have_css('div.sortable-item[data-sortable-item-pull="true"]', count: 2)
    )
    expect(page).to(
      have_css('div.sortable-item[data-sortable-item-pull="false"]', count: 1)
    )
  end

  it 'renders sortable with all options' do
    @options = {
      animation: 200,
      disabled: false,
      group_name: 'group_test_name',
      handle: '.handle',
      list_id: 10,
      list_param_name: 'list_id',
      resource_name: 'tasks',
      response_kind: 'html',
      position_param_name: 'position'
    }
    render_inline(component)

    div_data = [
      'div[data-sortable-list-animation-value="200"]',
      'div[data-sortable-list-disabled-value="false"]',
      'div[data-sortable-list-group-name-value="group_test_name"]',
      'div[data-sortable-list-handle-value=".handle"]',
      'div[data-sortable-list-list-id-value="10"]',
      'div[data-sortable-list-list-param-name-value="list_id"]',
      'div[data-sortable-list-resource-name-value="tasks"]',
      'div[data-sortable-list-response-kind-value="html"]',
      'div[data-sortable-list-position-param-name-value="position"]'
    ]

    div_data.each do |div|
      expect(page).to have_css div
    end
  end
end
