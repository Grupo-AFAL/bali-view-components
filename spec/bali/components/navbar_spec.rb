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
    described_class::COLORS.each do |color, classes|
      it "renders #{color} color" do
        render_inline(described_class.new(color: color))
        classes.split.each do |css_class|
          expect(page).to have_css "nav.navbar.#{css_class}"
        end
      end
    end

    it 'renders base color by default' do
      render_inline(described_class.new)
      expect(page).to have_css 'nav.navbar.bg-base-100'
    end

    it 'falls back to base for invalid color' do
      render_inline(described_class.new(color: :invalid))
      expect(page).to have_css 'nav.navbar.bg-base-100'
    end
  end

  describe 'accessibility' do
    it 'has navigation role' do
      render_inline(described_class.new)
      expect(page).to have_css 'nav[role="navigation"]'
    end

    it 'has aria-label' do
      render_inline(described_class.new)
      expect(page).to have_css 'nav[aria-label]'
    end

    it 'burger button has aria-label' do
      render_inline(described_class.new)
      expect(page).to have_css 'button[aria-label]'
    end
  end

  describe 'data attributes' do
    it 'includes stimulus controller' do
      render_inline(described_class.new)
      expect(page).to have_css 'nav[data-controller="navbar"]'
    end

    it 'includes throttle interval value' do
      render_inline(described_class.new)
      expect(page).to have_css 'nav[data-navbar-throttle-interval-value="100"]'
    end
  end

  describe 'custom options' do
    it 'passes through custom classes' do
      render_inline(described_class.new(class: 'custom-navbar'))
      expect(page).to have_css 'nav.navbar.custom-navbar'
    end

    it 'passes through data attributes' do
      render_inline(described_class.new(data: { testid: 'nav' }))
      expect(page).to have_css 'nav[data-testid="nav"]'
    end

    it 'supports container_class option' do
      render_inline(described_class.new(container_class: 'max-w-7xl'))
      expect(page).to have_css 'nav div.container.max-w-7xl'
    end
  end
end

RSpec.describe Bali::Navbar::Menu::Component, type: :component do
  it 'renders with DaisyUI menu classes' do
    render_inline(described_class.new) do |menu|
      menu.with_start_item(name: 'Link', href: '#')
    end

    expect(page).to have_css 'div.navbar-center.hidden'
    expect(page).to have_css 'ul.menu.menu-horizontal'
  end

  it 'renders end items' do
    render_inline(described_class.new) do |menu|
      menu.with_end_item(name: 'End', href: '#')
    end

    expect(page).to have_css 'a', text: 'End'
  end

  it 'sets correct data-navbar-target for main menu' do
    render_inline(described_class.new(type: :main))
    expect(page).to have_css '[data-navbar-target="menu"]'
  end

  it 'sets correct data-navbar-target for alt menu' do
    render_inline(described_class.new(type: :alt))
    expect(page).to have_css '[data-navbar-target="altMenu"]'
  end
end

RSpec.describe Bali::Navbar::Item::Component, type: :component do
  it 'renders as anchor by default' do
    render_inline(described_class.new(name: 'Link', href: '#'))
    expect(page).to have_css 'a[href="#"]', text: 'Link'
  end

  it 'renders with custom tag' do
    render_inline(described_class.new(tag_name: :div, name: 'Div'))
    expect(page).to have_css 'div', text: 'Div'
  end

  it 'renders content block' do
    render_inline(described_class.new(tag_name: :div)) { 'Block content' }
    expect(page).to have_css 'div', text: 'Block content'
  end

  it 'passes through custom attributes' do
    render_inline(described_class.new(name: 'Link', href: '#', class: 'custom'))
    expect(page).to have_css 'a.custom'
  end
end

RSpec.describe Bali::Navbar::Burger::Component, type: :component do
  it 'renders button with default icon' do
    render_inline(described_class.new)
    expect(page).to have_css 'button.btn.btn-ghost'
    expect(page).to have_css 'svg'
  end

  it 'has aria-label for accessibility' do
    render_inline(described_class.new)
    expect(page).to have_css 'button[aria-label]'
  end

  it 'sets correct data attributes for main type' do
    render_inline(described_class.new(type: :main))
    expect(page).to have_css '[data-navbar-target="burger"]'
    expect(page).to have_css '[data-action*="navbar#toggleMenu"]'
  end

  it 'sets correct data attributes for alt type' do
    render_inline(described_class.new(type: :alt))
    expect(page).to have_css '[data-navbar-target="altBurger"]'
    expect(page).to have_css '[data-action*="navbar#toggleAltMenu"]'
  end

  it 'renders custom content' do
    render_inline(described_class.new) { 'Custom icon' }
    expect(page).to have_css 'button', text: 'Custom icon'
  end

  it 'passes through custom classes' do
    render_inline(described_class.new(class: 'custom-burger'))
    expect(page).to have_css 'button.btn.btn-ghost.custom-burger'
  end
end
