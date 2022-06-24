# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::SideMenu::Component, type: :component do
  it 'renders the side menu' do
    render_inline Bali::SideMenu::Component.new do |c|
      c.list(title: 'Comedor') do |list|
        list.item(name: 'Item 1', href: '/pm/projects')
      end
    end

    expect(rendered_component).to have_css('.side-menu-component')
    expect(rendered_component).to have_css('p.menu-label', text: 'Comedor')
    expect(rendered_component).to have_css('ul.menu-list')
    expect(rendered_component).to have_css("a[href='/pm/projects']", text: 'Item 1')
  end
end
