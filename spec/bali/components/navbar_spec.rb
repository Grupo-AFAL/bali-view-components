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
      # Non-fullscreen: centered with max-width constraint
      expect(page).to have_css 'nav div.max-w-7xl.mx-auto'
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
      # Fullscreen: edge-to-edge, no max-width constraint
      expect(page).not_to have_css 'nav div.max-w-6xl'
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

    it 'skips color classes for unknown symbol' do
      render_inline(described_class.new(color: :invalid))
      expect(page).to have_css 'nav.navbar'
      expect(page).not_to have_css 'nav.navbar.bg-base-100'
    end

    it 'skips color classes when color is nil, allowing custom class' do
      render_inline(described_class.new(color: nil, class: 'bg-indigo-600 text-white'))
      expect(page).to have_css 'nav.navbar.bg-indigo-600.text-white'
      expect(page).not_to have_css 'nav.navbar.bg-base-100'
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
      render_inline(described_class.new(container_class: 'custom-container'))
      expect(page).to have_css 'nav div.custom-container'
    end
  end
end

RSpec.describe Bali::Navbar::Menu::Component, type: :component do
  it 'renders with DaisyUI menu classes' do
    render_inline(described_class.new) do |menu|
      menu.with_start_item(name: 'Link', href: '#')
    end

    # Outer wrapper is hidden on mobile, visible on desktop (lg:flex)
    expect(page).to have_css 'div.hidden'
    # Menu uses responsive horizontal classes
    expect(page).to have_css 'ul.menu'
  end

  it 'renders end items in flex container with ml-auto on desktop' do
    render_inline(described_class.new) do |menu|
      menu.with_end_item(name: 'End', href: '#')
    end

    # ml-auto is responsive (lg:ml-auto)
    expect(page).to have_css 'div[class*="lg:ml-auto"] a', text: 'End'
  end

  it 'sets correct data-navbar-target for main menu with start_items' do
    render_inline(described_class.new(type: :main)) do |menu|
      menu.with_start_item(name: 'Link', href: '#')
    end
    expect(page).to have_css 'div[data-navbar-target="menu"]'
  end

  it 'sets correct data-navbar-target for alt menu with end_items' do
    render_inline(described_class.new(type: :alt)) do |menu|
      menu.with_end_item(name: 'Action', href: '#')
    end
    expect(page).to have_css 'div[data-navbar-target="altMenu"]'
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

  context 'with href' do
    it 'renders as a link' do
      render_inline(described_class.new(href: '/menu'))
      expect(page).to have_css 'a.btn.btn-ghost[href="/menu"]'
      expect(page).to have_no_css 'button'
    end

    it 'renders with default icon' do
      render_inline(described_class.new(href: '/menu'))
      expect(page).to have_css 'a svg'
    end

    it 'renders custom content' do
      render_inline(described_class.new(href: '/menu')) { 'Menu' }
      expect(page).to have_css 'a', text: 'Menu'
    end

    it 'has aria-label for accessibility' do
      render_inline(described_class.new(href: '/menu'))
      expect(page).to have_css 'a[aria-label]'
    end

    it 'does not add stimulus data attributes' do
      render_inline(described_class.new(href: '/menu', type: :main))
      expect(page).to have_no_css '[data-navbar-target]'
      expect(page).to have_no_css '[data-action]'
    end
  end
end
