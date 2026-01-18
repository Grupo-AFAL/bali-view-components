# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::TreeView::Component, type: :component do
  let(:component) { described_class.new(current_path: '/') }

  describe 'basic rendering' do
    it 'renders a tree container with proper role' do
      render_inline(component) do |c|
        c.with_item(name: 'Item 1', path: '/items/1')
      end

      expect(page).to have_css '.tree-view-component[role="tree"]'
    end

    it 'renders root items' do
      render_inline(component) do |c|
        c.with_item(name: 'Item 1', path: '/items/1')
        c.with_item(name: 'Item 2', path: '/items/2')
        c.with_item(name: 'Item 3', path: '/items/3')
      end

      expect(page).to have_css '.tree-view-component'
      expect(page).to have_css '.tree-view-item-component .item.is-root', text: 'Item 1'
      expect(page).to have_css '.tree-view-item-component .item.is-root', text: 'Item 2'
      expect(page).to have_css '.tree-view-item-component .item.is-root', text: 'Item 3'
    end

    it 'renders sub items' do
      render_inline(component) do |c|
        c.with_item(name: 'Item 1', path: '/items/1') do |sub|
          sub.with_item(name: 'Child 1', path: '/items/1a')
        end
      end

      expect(page).to have_css '.tree-view-component'
      expect(page).to have_css '.children .item', text: 'Child 1'
    end

    it 'renders empty tree' do
      render_inline(component)

      expect(page).to have_css '.tree-view-component[role="tree"]'
    end
  end

  describe 'active state' do
    it 'marks the active item with is-active class' do
      render_inline(described_class.new(current_path: '/items/1')) do |c|
        c.with_item(name: 'Item 1', path: '/items/1')
        c.with_item(name: 'Item 2', path: '/items/2')
      end

      expect(page).to have_css '.item.is-active', text: 'Item 1'
      expect(page).to have_no_css '.item.is-active', text: 'Item 2'
    end

    it 'expands parent when child is active' do
      render_inline(described_class.new(current_path: '/items/1a')) do |c|
        c.with_item(name: 'Item 1', path: '/items/1') do |sub|
          sub.with_item(name: 'Child 1', path: '/items/1a')
        end
      end

      expect(page).to have_css '.children:not(.hidden)', text: 'Child 1'
    end
  end

  describe 'childless items' do
    it 'marks items without children as childless' do
      render_inline(component) do |c|
        c.with_item(name: 'Leaf', path: '/leaf')
      end

      expect(page).to have_css '.item.is-childless', text: 'Leaf'
    end

    it 'does not mark items with children as childless' do
      render_inline(component) do |c|
        c.with_item(name: 'Parent', path: '/parent') do |sub|
          sub.with_item(name: 'Child', path: '/child')
        end
      end

      expect(page).to have_no_css '.item.is-childless', text: 'Parent'
    end
  end

  describe 'ARIA accessibility' do
    it 'sets role="treeitem" on items' do
      render_inline(component) do |c|
        c.with_item(name: 'Item', path: '/item')
      end

      expect(page).to have_css '.tree-view-item-component[role="treeitem"]'
    end

    it 'sets aria-expanded on items with children' do
      render_inline(described_class.new(current_path: '/parent')) do |c|
        c.with_item(name: 'Parent', path: '/parent') do |sub|
          sub.with_item(name: 'Child', path: '/child')
        end
      end

      expect(page).to have_css '[aria-expanded="true"]'
    end

    it 'sets role="group" on children containers' do
      render_inline(component) do |c|
        c.with_item(name: 'Parent', path: '/parent') do |sub|
          sub.with_item(name: 'Child', path: '/child')
        end
      end

      expect(page).to have_css '.children[role="group"]'
    end
  end

  describe 'nested levels' do
    # Note: ViewComponent's renders_many with lambdas only supports 2 levels of nesting.
    # Three-level deep nesting requires a different architectural approach.
    it 'renders two levels deep when nested item is active' do
      render_inline(described_class.new(current_path: '/l1/l2')) do |c|
        c.with_item(name: 'Level 1', path: '/l1') do |l1|
          l1.with_item(name: 'Level 2', path: '/l1/l2')
        end
      end

      # Level 2 is active, so parent children container should be expanded
      expect(page).to have_css '.children:not(.hidden) .item.is-active', text: 'Level 2'
    end

    it 'renders collapsed nested items when not active' do
      render_inline(described_class.new(current_path: '/other')) do |c|
        c.with_item(name: 'Level 1', path: '/l1') do |l1|
          l1.with_item(name: 'Level 2', path: '/l1/l2')
        end
      end

      # Children should be hidden when not active
      expect(page).to have_css '.children.hidden'
    end
  end

  describe 'Stimulus integration' do
    it 'sets up tree-view-item controller' do
      render_inline(component) do |c|
        c.with_item(name: 'Item', path: '/item')
      end

      expect(page).to have_css '[data-controller="tree-view-item"]'
    end

    it 'sets url value for navigation' do
      render_inline(component) do |c|
        c.with_item(name: 'Item', path: '/custom/path')
      end

      expect(page).to have_css '[data-tree-view-item-url-value="/custom/path"]'
    end

    it 'sets caret target' do
      render_inline(component) do |c|
        c.with_item(name: 'Item', path: '/item')
      end

      expect(page).to have_css '[data-tree-view-item-target="caret"]'
    end

    it 'sets children target' do
      render_inline(component) do |c|
        c.with_item(name: 'Item', path: '/item') do |sub|
          sub.with_item(name: 'Child', path: '/child')
        end
      end

      expect(page).to have_css '[data-tree-view-item-target="children"]'
    end
  end

  describe 'custom options' do
    it 'accepts custom class on tree container' do
      render_inline(described_class.new(current_path: '/', class: 'custom-tree')) do |c|
        c.with_item(name: 'Item', path: '/item')
      end

      expect(page).to have_css '.tree-view-component.custom-tree'
    end

    it 'accepts custom class on items' do
      render_inline(component) do |c|
        c.with_item(name: 'Item', path: '/item', class: 'custom-item')
      end

      expect(page).to have_css '.tree-view-item-component.custom-item'
    end

    it 'accepts custom data attributes on items' do
      render_inline(component) do |c|
        c.with_item(name: 'Item', path: '/item', data: { testid: 'my-item' })
      end

      expect(page).to have_css '[data-testid="my-item"]'
    end
  end
end

RSpec.describe Bali::TreeView::Item::Component, type: :component do
  describe 'constants' do
    it 'has BASE_CLASSES constant' do
      expect(described_class::BASE_CLASSES).to eq 'tree-view-item-component'
    end

    it 'has CONTROLLER_NAME constant' do
      expect(described_class::CONTROLLER_NAME).to eq 'tree-view-item'
    end

    it 'has frozen ITEM_CLASSES constant' do
      expect(described_class::ITEM_CLASSES).to be_frozen
    end

    it 'has frozen CARET_CLASSES constant' do
      expect(described_class::CARET_CLASSES).to be_frozen
    end
  end
end
