# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Navbar::Component, type: :component do
  before { @options = {} }
  let(:component) { Bali::Navbar::Component.new(**@options) }

  context 'without fullscreen' do
    before { @options.merge!(fullscreen: false) }

    it 'renders navbar component' do
      render_inline(component) do |c|
        c.brand { '<h4 class="title is-5 has-text-white">Bali</h4>'.html_safe }
        c.menu do |menu|
          menu.start_items([
                             { name: 'Tech Stack', href: '#' },
                             { name: 'Projects', href: '#' },
                             { name: 'Team', href: '#' },
                             { name: 'Open Positions', href: '#' }
                           ])
        end
      end

      expect(page).to have_css 'h4.title.is-5', text: 'Bali'
      expect(page).to have_css 'a.navbar-item', text: 'Tech Stack'
      expect(page).to have_css 'a.navbar-item', text: 'Projects'
      expect(page).to have_css 'a.navbar-item', text: 'Team'
      expect(page).to have_css 'a.navbar-item', text: 'Open Positions'
      expect(page).to have_css 'a.navbar-burger'
      expect(page).to have_css 'nav div.container'
    end
  end

  context 'with fullscreen' do
    before { @options.merge!(fullscreen: true) }

    it 'renders navbar component with fullscreen' do
      render_inline(component) do |c|
        c.brand { '<h4 class="title is-5 has-text-white">Bali</h4>'.html_safe }
        c.menu do |menu|
          menu.start_items([{ name: 'Tech Stack', href: '#' }])
        end
      end

      expect(page).to have_css 'h4.title.is-5', text: 'Bali'
      expect(page).to have_css 'a.navbar-item', text: 'Tech Stack'
      expect(page).to have_css 'a.navbar-burger'
      expect(page).not_to have_css 'nav div.container'
    end
  end

  context 'with transparency enabled' do
    before { @options.merge!(transparency: true) }

    it 'renders navbar component with fullscreen' do
      render_inline(component) do |c|
        c.brand { '<h4 class="title is-5 has-text-white">Bali</h4>'.html_safe }
        c.menu do |menu|
          menu.start_items([{ name: 'Tech Stack', href: '#' }])
        end
      end

      expect(page).to have_css 'h4.title.is-5', text: 'Bali'
      expect(page).to have_css '[data-navbar-allow-transparency-value="true"]'
    end
  end

  context 'with custom burger button' do
    it 'renders navbar component with fullscreen' do
      render_inline(component) do |c|
        c.brand { '<h4 class="title is-5 has-text-white">Bali</h4>'.html_safe }
        c.burger(class: 'custom-burger')
        c.menu do |menu|
          menu.start_items([{ name: 'Tech Stack', href: '#' }])
        end
      end

      expect(page).to have_css 'h4.title.is-5', text: 'Bali'
      expect(page).to have_css 'a.navbar-burger.burger.custom-burger'
    end
  end

  context 'with multiple menu and burgers' do
    it 'renders navbar component with fullscreen' do
      render_inline(component) do |c|
        c.brand { '<h4 class="title is-5 has-text-white">Bali</h4>'.html_safe }
        c.burger(class: 'custom-burger')
        c.burger(type: :alt)
        c.menu do |menu|
          menu.start_items([{ name: 'Tech Stack', href: '#' }])
        end

        c.menu(type: :alt) do |menu|
          menu.end_items([{ name: 'About us', href: '#' }])
        end
      end

      expect(page).to have_css 'h4.title.is-5', text: 'Bali'
      expect(page).to have_css '[data-navbar-target="burger"]'
      expect(page).to have_css '[data-navbar-target="altBurger"]'
      expect(page).to have_css '[data-navbar-target="menu"]'
      expect(page).to have_css '[data-navbar-target="altMenu"]'
    end
  end
end
