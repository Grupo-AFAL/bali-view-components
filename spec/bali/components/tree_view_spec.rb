# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::TreeView::Component, type: :component do
  let(:component) { Bali::TreeView::Component.new(current_path: '/') }

  it 'renders root items' do
    render_inline(component) do |c|
      c.item(name: 'Item 1', path: '/items/1')
      c.item(name: 'Item 2', path: '/items/2')
      c.item(name: 'Item 3', path: '/items/3')
    end

    expect(page).to have_css '.tree-view-component'
    expect(page).to have_css '.tree-view-item-component .item.is-root', text: 'Item 1'
    expect(page).to have_css '.tree-view-item-component .item.is-root', text: 'Item 2'
    expect(page).to have_css '.tree-view-item-component .item.is-root', text: 'Item 3'
  end

  it 'renders sub items' do
    render_inline(component) do |c|
      c.item(name: 'Item 1', path: '/items/1') do |sub|
        sub.item(name: 'Child 1', path: '/items/1a')
      end
    end

    expect(page).to have_css '.tree-view-component'
    expect(page).to have_css '.children .item', text: 'Child 1'
  end
end
