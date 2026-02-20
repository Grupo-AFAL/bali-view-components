# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::SideMenu::Component, type: :component do
  before { @options = { current_path: '/' } }
  let(:component) { Bali::SideMenu::Component.new(**@options) }

  it 'renders the side menu' do
    render_inline(component) do |c|
      c.with_list(title: 'Comedor') do |list|
        list.with_item(name: 'Item 1', href: '/movies')
      end
    end

    expect(page).to have_css('.side-menu-component')
    expect(page).to have_css('p.menu-label', text: 'Comedor')
    expect(page).to have_css('.sidebar-menu')
    expect(page).to have_css("a[href='/movies']", text: 'Item 1')
  end

  it 'renders the side menu with icon' do
    render_inline(component) do |c|
      c.with_list(title: 'Section title') do |list|
        list.with_item(name: 'Item 1', href: '#', icon: 'attachment')
      end
    end

    expect(page).to have_css '.side-menu-component'
    expect(page).to have_css 'a > span.icon-component'
    expect(page).to have_css 'a', text: 'Item 1'
  end

  context 'when not authorized' do
    it 'does not render the link' do
      render_inline(component) do |c|
        c.with_list(title: 'Section title') do |list|
          list.with_item(name: 'item', href: '#', authorized: false)
        end
      end

      expect(page).to have_css '.side-menu-component'
      expect(page).not_to have_css 'li > a'
    end
  end

  context 'with crud match' do
    it 'renders as active when current path is the new path' do
      @options[:current_path] = '/items/new'
      render_inline(component) do |c|
        c.with_list do |list|
          list.with_item(name: 'items', href: '/items', match: :crud)
        end
      end

      expect(page).to have_css 'a.active', text: 'items'
    end

    it 'renders as active when current path is the item show path' do
      @options[:current_path] = '/items/123'
      render_inline(component) do |c|
        c.with_list do |list|
          list.with_item(name: 'items', href: '/items', match: :crud)
        end
      end

      expect(page).to have_css 'a.active', text: 'items'
    end

    it 'renders as active when current path is the item edit path' do
      @options[:current_path] = '/items/123/edit'
      render_inline(component) do |c|
        c.with_list do |list|
          list.with_item(name: 'items', href: '/items', match: :crud)
        end
      end

      expect(page).to have_css 'a.active', text: 'items'
    end

    it 'renders as active when current path is the item index path' do
      @options[:current_path] = '/items'
      render_inline(component) do |c|
        c.with_list do |list|
          list.with_item(name: 'items', href: '/items', match: :crud)
        end
      end

      expect(page).to have_css 'a.active', text: 'items'
    end

    it 'renders as inactive when current path is not a CRUD action' do
      @options[:current_path] = '/items/dashboard'
      render_inline(component) do |c|
        c.with_list do |list|
          list.with_item(name: 'items', href: '/items', match: :crud)
        end
      end

      expect(page).not_to have_css 'a.active', text: 'items'
    end
  end

  context 'with starts_with match' do
    it 'renders as active when current path starts with item href' do
      @options[:current_path] = '/item'
      render_inline(component) do |c|
        c.with_list do |list|
          list.with_item(name: 'item root', href: '/item', match: :starts_with)
        end
      end

      expect(page).to have_css 'a.active', text: 'item root'
    end

    it 'renders as inactive when href is included within current path' do
      @options[:current_path] = '/section/item'
      render_inline(component) do |c|
        c.with_list do |list|
          list.with_item(name: 'item root', href: '/item', match: :starts_with)
        end
      end

      expect(page).not_to have_css 'a.active', text: 'item root'
    end
  end

  context 'with partial match' do
    it 'renders an active link' do
      @options[:current_path] = '/section/item/menu'
      render_inline(component) do |c|
        c.with_list(title: 'Section title') do |list|
          list.with_item(name: 'item root', href: '/item', match: :partial)
          list.with_item(name: 'item menu', href: '/section/item/menu')
        end
      end

      expect(page).to have_css 'a.active', text: 'item root'
      expect(page).to have_css 'a.active', text: 'item menu'
    end
  end

  context 'with exact match' do
    it 'renders an active link' do
      @options[:current_path] = '/item'
      render_inline(component) do |c|
        c.with_list(title: 'Section title') do |list|
          list.with_item(name: 'item root', href: '/item')
          list.with_item(name: 'item 1', href: '/item/1')
        end
      end

      expect(page).to have_css 'a.active', text: 'item root'
      expect(page).not_to have_css 'a.active', text: 'item 1'
    end
  end

  it 'passes data attributes through to the anchor tag' do
    render_inline(component) do |c|
      c.with_list do |list|
        list.with_item(name: 'Sign Out', href: '/logout', data: { turbo_method: :delete })
      end
    end

    expect(page).to have_css 'a[data-turbo-method="delete"]', text: 'Sign Out'
  end

  it 'renders a disabled link' do
    render_inline(component) do |c|
      c.with_list(title: 'Section title') do |list|
        list.with_item(name: 'Item', href: '#', disabled: true)
      end
    end

    expect(page).to have_css 'a[disabled="disabled"]', text: 'Item'
  end

  context 'with bottom items' do
    it 'renders bottom items outside the scrollable area' do
      render_inline(component) do |c|
        c.with_list do |list|
          list.with_item(name: 'Dashboard', href: '/dashboard')
        end
        c.with_bottom_item(name: 'Profile', href: '/profile')
        c.with_bottom_item(name: 'Sign Out', href: '/sign_out')
      end

      expect(page).to have_css 'a', text: 'Profile'
      expect(page).to have_css 'a', text: 'Sign Out'
    end

    it 'renders bottom items with icons' do
      render_inline(component) do |c|
        c.with_bottom_item(name: 'Profile', href: '/profile', icon: 'user')
      end

      expect(page).to have_css 'a', text: 'Profile'
    end

    it 'does not render bottom section when no bottom items are given' do
      render_inline(component) do |c|
        c.with_list do |list|
          list.with_item(name: 'Dashboard', href: '/dashboard')
        end
      end

      expect(page).not_to have_css '.border-t.border-base-200.shrink-0'
    end

    it 'skips unauthorized bottom items' do
      render_inline(component) do |c|
        c.with_bottom_item(name: 'Profile', href: '/profile', authorized: true)
        c.with_bottom_item(name: 'Admin', href: '/admin', authorized: false)
      end

      expect(page).to have_css 'a', text: 'Profile'
      expect(page).not_to have_css 'a', text: 'Admin'
    end

    it 'marks active bottom item based on current_path' do
      @options[:current_path] = '/profile'
      render_inline(component) do |c|
        c.with_bottom_item(name: 'Profile', href: '/profile')
        c.with_bottom_item(name: 'Sign Out', href: '/sign_out')
      end

      expect(page).to have_css 'a.active', text: 'Profile'
      expect(page).not_to have_css 'a.active', text: 'Sign Out'
    end
  end
end
