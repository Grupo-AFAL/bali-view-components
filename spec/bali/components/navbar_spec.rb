# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Navbar::Component, type: :component do
  before { @options = {} }
  let(:component) { Bali::Navbar::Component.new(**@options) }

  context 'without fullscreen' do
    before { @options.merge!(fullscreen: false) }

    it 'renders navbar component' do
      render_inline(component) do |c|
        c.with_brand { '<a class="btn btn-ghost text-xl">Bali</a>'.html_safe }
        c.with_menu do |menu|
          menu.with_start_items([
                                  { name: 'Tech Stack', href: '#' },
                                  { name: 'Projects', href: '#' },
                                  { name: 'Team', href: '#' },
                                  { name: 'Open Positions', href: '#' }
                                ])
        end
      end

      expect(page).to have_css 'a.btn.btn-ghost', text: 'Bali'
      expect(page).to have_css 'a', text: 'Tech Stack'
      expect(page).to have_css 'a', text: 'Projects'
      expect(page).to have_css 'a', text: 'Team'
      expect(page).to have_css 'a', text: 'Open Positions'
      expect(page).to have_css 'button.btn.btn-ghost'
      expect(page).to have_css 'nav div.container'
    end
  end

  context 'with fullscreen' do
    before { @options.merge!(fullscreen: true) }

    it 'renders navbar component with fullscreen' do
      render_inline(component) do |c|
        c.with_brand { '<a class="btn btn-ghost text-xl">Bali</a>'.html_safe }
        c.with_menu do |menu|
          menu.with_start_items([{ name: 'Tech Stack', href: '#' }])
        end
      end

      expect(page).to have_css 'a.btn.btn-ghost', text: 'Bali'
      expect(page).to have_css 'a', text: 'Tech Stack'
      expect(page).to have_css 'button.btn.btn-ghost'
      expect(page).not_to have_css 'nav div.container'
    end
  end

  context 'with transparency enabled' do
    before { @options.merge!(transparency: true) }

    it 'renders navbar component with transparency data attribute' do
      render_inline(component) do |c|
        c.with_brand { '<a class="btn btn-ghost text-xl">Bali</a>'.html_safe }
        c.with_menu do |menu|
          menu.with_start_items([{ name: 'Tech Stack', href: '#' }])
        end
      end

      expect(page).to have_css 'a.btn.btn-ghost', text: 'Bali'
      expect(page).to have_css '[data-navbar-allow-transparency-value="true"]'
    end
  end

  context 'with custom burger button' do
    it 'renders navbar component with custom burger' do
      render_inline(component) do |c|
        c.with_brand { '<a class="btn btn-ghost text-xl">Bali</a>'.html_safe }
        c.with_burger(class: 'custom-burger')
        c.with_menu do |menu|
          menu.with_start_items([{ name: 'Tech Stack', href: '#' }])
        end
      end

      expect(page).to have_css 'a.btn.btn-ghost', text: 'Bali'
      expect(page).to have_css 'button.btn.btn-ghost.custom-burger'
    end
  end

  context 'with multiple menu and burgers' do
    it 'renders navbar component with multiple menus' do
      render_inline(component) do |c|
        c.with_brand { '<a class="btn btn-ghost text-xl">Bali</a>'.html_safe }
        c.with_burger(class: 'custom-burger')
        c.with_burger(type: :alt)
        c.with_menu do |menu|
          menu.with_start_items([{ name: 'Tech Stack', href: '#' }])
        end

        c.with_menu(type: :alt) do |menu|
          menu.with_end_items([{ name: 'About us', href: '#' }])
        end
      end

      expect(page).to have_css 'a.btn.btn-ghost', text: 'Bali'
      expect(page).to have_css '[data-navbar-target="burger"]'
      expect(page).to have_css '[data-navbar-target="altBurger"]'
      expect(page).to have_css '[data-navbar-target="menu"]'
      expect(page).to have_css '[data-navbar-target="altMenu"]'
    end
  end

  context 'with colors' do
    it 'renders primary color' do
      render_inline(described_class.new(color: :primary))
      expect(page).to have_css 'nav.navbar.bg-primary.text-primary-content'
    end

    it 'renders base color by default' do
      render_inline(described_class.new)
      expect(page).to have_css 'nav.navbar.bg-base-100'
    end
  end
end
