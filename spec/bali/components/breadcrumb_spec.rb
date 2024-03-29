# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Breadcrumb::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Breadcrumb::Component.new(**options) }

  it 'renders breadcrumb component' do
    render_inline(component) do |c|
      c.with_item(href: '/home', name: 'Home')
      c.with_item(href: '/home/section', name: 'Section')
      c.with_item(href: '/home/section/page', name: 'Page', active: true)
    end

    expect(page).to have_css 'nav.breadcrumb-component'
    expect(page).to have_css 'li a[href="/home"]', text: 'Home'
    expect(page).to have_css 'li a[href="/home/section"]', text: 'Section'
    expect(page).to have_css 'li.is-active a[href="/home/section/page"]', text: 'Page'
  end

  it 'renders breadcrumb with icons' do
    render_inline(component) do |c|
      c.with_item(href: '/home', name: 'Home', icon_name: 'home')
    end

    expect(page).to have_css 'li a span.icon'
    expect(page).to have_css 'li a span', text: 'Home'
  end

  it 'renders breadcrumb with custom classes' do
    options[:class] = 'is-centered is-small'
    render_inline(component) do |c|
      c.with_item(href: '/home', name: 'Home', icon_name: 'home')
    end

    expect(page).to have_css 'nav.breadcrumb-component.is-centered.is-small'
  end
end
