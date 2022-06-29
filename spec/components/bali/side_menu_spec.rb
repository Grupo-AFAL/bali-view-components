# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::SideMenu::Component, type: :component do
  let(:component) { Bali::SideMenu::Component.new }

  it 'renders the side menu' do
    render_inline(component) do |c|
      c.list(title: 'Comedor') do |list|
        list.item(name: 'Item 1', href: '/movies')
      end
    end

    expect(rendered_component).to have_css('.side-menu-component')
    expect(rendered_component).to have_css('p.menu-label', text: 'Comedor')
    expect(rendered_component).to have_css('ul.menu-list')
    expect(rendered_component).to have_css("a[href='/movies']", text: 'Item 1')
  end

  it 'renders the side menu with icon' do
    render_inline(component) do |c|
      c.list(title: 'Section title') do |list|
        list.item(name: 'Item 1', href: '#', icon: 'attachment')
      end
    end

    expect(rendered_component).to have_css '.side-menu-component'
    expect(rendered_component).to have_css 'a > span.icon-component.icon'
    expect(rendered_component).to have_css 'a', text: 'Item 1'
  end

  context 'when not authorized' do
    it 'does not render the link' do
      render_inline(component) do |c|
        c.list(title: 'Section title') do |list|
          list.item(name: 'item', href: '#', authorized: false)
        end
      end

      expect(rendered_component).to have_css '.side-menu-component'
      expect(rendered_component).not_to have_css 'li > a'
    end
  end

  it 'renders an active link' do
    with_request_url '/#' do
      render_inline(component) do |c|
        c.list(title: 'Section title') do |list|
          list.item(name: 'item', href: '/#')
        end
      end
    end

    expect(rendered_component).to have_css 'a.is-active', text: 'item'
  end
end
