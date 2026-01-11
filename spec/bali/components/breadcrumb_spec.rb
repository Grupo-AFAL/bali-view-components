# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Breadcrumb::Component, type: :component do
  describe 'basic rendering' do
    it 'renders breadcrumb with DaisyUI classes' do
      render_inline(described_class.new) do |c|
        c.with_item(href: '/home', name: 'Home')
        c.with_item(href: '/home/section', name: 'Section')
        c.with_item(href: '/home/section/page', name: 'Page', active: true)
      end

      expect(page).to have_css 'nav.breadcrumbs.breadcrumb-component'
      expect(page).to have_css 'li a[href="/home"]', text: 'Home'
      expect(page).to have_css 'li a[href="/home/section"]', text: 'Section'
      expect(page).to have_css 'li a[href="/home/section/page"]', text: 'Page'
    end

    it 'renders active item with font-semibold' do
      render_inline(described_class.new) do |c|
        c.with_item(href: '/page', name: 'Page', active: true)
      end

      expect(page).to have_css 'li a.font-semibold', text: 'Page'
    end
  end

  describe 'with icons' do
    it 'renders breadcrumb items with icons' do
      render_inline(described_class.new) do |c|
        c.with_item(href: '/home', name: 'Home', icon_name: 'home')
      end

      expect(page).to have_css 'li a', text: 'Home'
    end
  end

  describe 'custom classes' do
    it 'merges custom classes' do
      render_inline(described_class.new(class: 'my-custom-class')) do |c|
        c.with_item(href: '/home', name: 'Home')
      end

      expect(page).to have_css 'nav.breadcrumbs.breadcrumb-component.my-custom-class'
    end
  end
end
