# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::TreeView::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::TreeView::Component.new(**options) }

  subject { rendered_component }

  before do
    allow_any_instance_of(Bali::TreeView::Item::Component)
      .to receive(:active_path?).and_return(false)
  end

  it 'renders root items' do
    render_inline(component) do |c|
      c.item(name: 'Item 1', path: '/items/1')
      c.item(name: 'Item 2', path: '/items/2')
      c.item(name: 'Item 3', path: '/items/3')
    end

    is_expected.to have_css '.tree-view-component'
    is_expected.to have_css '.tree-view-item-component .item.is-root', text: 'Item 1'
    is_expected.to have_css '.tree-view-item-component .item.is-root', text: 'Item 2'
    is_expected.to have_css '.tree-view-item-component .item.is-root', text: 'Item 3'
  end

  it 'renders sub items' do
    render_inline(component) do |c|
      c.item(name: 'Item 1', path: '/items/1') do |sub|
        sub.item(name: 'Child 1', path: '/items/1a')
      end
    end

    is_expected.to have_css '.tree-view-component'
    is_expected.to have_css '.children .item', text: 'Child 1'
  end
end
