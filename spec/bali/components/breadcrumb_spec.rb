# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Breadcrumb::Component, type: :component do
  describe 'basic rendering' do
    it 'renders breadcrumb with DaisyUI classes' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Home', href: '/home')
        c.with_item(name: 'Section', href: '/home/section')
        c.with_item(name: 'Page')
      end

      expect(page).to have_css 'nav.breadcrumbs.text-sm'
      expect(page).to have_css 'li a[href="/home"]', text: 'Home'
      expect(page).to have_css 'li a[href="/home/section"]', text: 'Section'
      expect(page).to have_css 'li span', text: 'Page'
    end

    it 'renders active item as non-clickable span' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Page', href: '/page', active: true)
      end

      expect(page).to have_css 'li span.cursor-default', text: 'Page'
    end

    it 'auto-activates item when href is nil' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Current Page')
      end

      expect(page).to have_css 'li span.cursor-default', text: 'Current Page'
      expect(page).not_to have_css 'li a'
    end
  end

  describe 'accessibility' do
    it 'has aria-label on nav element' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Home', href: '/home')
      end

      expect(page).to have_css 'nav[aria-label="Breadcrumb"]'
    end

    it 'adds aria-current="page" to active item' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Home', href: '/home')
        c.with_item(name: 'Current Page')
      end

      expect(page).to have_css 'li span[aria-current="page"]', text: 'Current Page'
    end

    it 'adds aria-current="page" to explicitly active item' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Page', href: '/page', active: true)
      end

      expect(page).to have_css 'li span[aria-current="page"]', text: 'Page'
    end
  end

  describe 'with icons' do
    it 'renders breadcrumb items with icons' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Home', href: '/home', icon_name: 'home')
      end

      expect(page).to have_css 'li a', text: 'Home'
      expect(page).to have_css 'li a svg'
    end

    it 'renders icon on non-link items' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Current', icon_name: 'home')
      end

      expect(page).to have_css 'li span', text: 'Current'
      expect(page).to have_css 'li span svg'
    end
  end

  describe 'custom classes' do
    it 'merges custom classes on container' do
      render_inline(described_class.new(class: 'my-custom-class')) do |c|
        c.with_item(name: 'Home', href: '/home')
      end

      expect(page).to have_css 'nav.breadcrumbs.my-custom-class'
    end

    it 'merges custom classes on item' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Home', href: '/home', class: 'item-custom')
      end

      expect(page).to have_css 'li.item-custom'
    end
  end

  describe 'link behavior' do
    it 'renders as link when href provided and not active' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Section', href: '/section')
      end

      expect(page).to have_css 'li a[href="/section"]', text: 'Section'
      expect(page).to have_css 'li a.no-underline'
    end

    it 'renders as span when active even with href' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Section', href: '/section', active: true)
      end

      expect(page).to have_css 'li span', text: 'Section'
      expect(page).not_to have_css 'li a'
    end

    it 'allows explicit active: false to keep link behavior' do
      render_inline(described_class.new) do |c|
        c.with_item(name: 'Current', active: false, href: '/current')
      end

      expect(page).to have_css 'li a[href="/current"]', text: 'Current'
    end
  end
end
