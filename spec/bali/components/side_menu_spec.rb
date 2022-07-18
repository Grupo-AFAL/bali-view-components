# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::SideMenu::Component, type: :component do
  before { @options = { current_path: '/' } }
  let(:component) { Bali::SideMenu::Component.new(**@options) }

  it 'renders the side menu' do
    render_inline(component) do |c|
      c.list(title: 'Comedor') do |list|
        list.item(name: 'Item 1', href: '/movies')
      end
    end

    expect(page).to have_css('.side-menu-component')
    expect(page).to have_css('p.menu-label', text: 'Comedor')
    expect(page).to have_css('ul.menu-list')
    expect(page).to have_css("a[href='/movies']", text: 'Item 1')
  end

  it 'renders the side menu with icon' do
    render_inline(component) do |c|
      c.list(title: 'Section title') do |list|
        list.item(name: 'Item 1', href: '#', icon: 'attachment')
      end
    end

    expect(page).to have_css '.side-menu-component'
    expect(page).to have_css 'a > span.icon-component.icon'
    expect(page).to have_css 'a', text: 'Item 1'
  end

  context 'when not authorized' do
    it 'does not render the link' do
      render_inline(component) do |c|
        c.list(title: 'Section title') do |list|
          list.item(name: 'item', href: '#', authorized: false)
        end
      end

      expect(page).to have_css '.side-menu-component'
      expect(page).not_to have_css 'li > a'
    end
  end

  context 'with partial match' do
    it 'renders an active link' do
      @options[:current_path] = '/item/menu'
      render_inline(component) do |c|
        c.list(title: 'Section title') do |list|
          list.item(name: 'item root', href: '/item', match: :partial)
          list.item(name: 'item menu', href: '/item/menu')
        end
      end

      expect(page).to have_css 'a.is-active', text: 'item root'
      expect(page).to have_css 'a.is-active', text: 'item menu'
    end
  end

  context 'with exact match' do
    it 'renders an active link' do
      @options[:current_path] = '/item'
      render_inline(component) do |c|
        c.list(title: 'Section title') do |list|
          list.item(name: 'item root', href: '/item')
          list.item(name: 'item 1', href: '/item/1')
        end
      end

      expect(page).to have_css 'a.is-active', text: 'item root'
      expect(page).not_to have_css 'a.is-active', text: 'item 1'
    end
  end

  it 'renders a disabled link' do
    render_inline(component) do |c|
      c.list(title: 'Section title') do |list|
        list.item(name: 'Item', href: '#', disabled: true)
      end
    end

    expect(page).to have_css 'a[disabled="disabled"]', text: 'Item'
  end
end
