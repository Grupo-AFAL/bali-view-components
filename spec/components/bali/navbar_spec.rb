# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Navbar::Component, type: :component do
  let(:component) { Bali::Navbar::Component.new(**@options) }
  before { @options = {} }

  subject { rendered_component }

  context 'without fullscreen' do
    before { @options.merge!(fullscreen: false) }

    it 'renders navbar component' do
      render_inline(component) do |c|
        c.brand { '<h4 class="title is-5 has-text-white">Bali</h4>'.html_safe }
        c.left_items([
                       { name: 'Tech Stack', href: '#' },
                       { name: 'Projects', href: '#' },
                       { name: 'Team', href: '#' },
                       { name: 'Open Positions', href: '#' }
                     ])
      end

      is_expected.to have_css 'h4.title.is-5', text: 'Bali'
      is_expected.to have_css 'a.navbar-item', text: 'Tech Stack'
      is_expected.to have_css 'a.navbar-item', text: 'Projects'
      is_expected.to have_css 'a.navbar-item', text: 'Team'
      is_expected.to have_css 'a.navbar-item', text: 'Open Positions'
      is_expected.to have_css 'a.navbar-burger'
      is_expected.to have_css 'nav div.container'
    end
  end

  context 'with fullscreen' do
    before { @options.merge!(fullscreen: true) }

    it 'renders navbar component with fullscreen' do
      render_inline(component) do |c|
        c.brand { '<h4 class="title is-5 has-text-white">Bali</h4>'.html_safe }
        c.left_items([{ name: 'Tech Stack', href: '#' }])
      end

      is_expected.to have_css 'h4.title.is-5', text: 'Bali'
      is_expected.to have_css 'a.navbar-item', text: 'Tech Stack'
      is_expected.to have_css 'a.navbar-burger'
      is_expected.not_to have_css 'nav div.container'
    end
  end

  context 'with transparency enabled' do
    before { @options.merge!(transparency: true) }

    it 'renders navbar component with fullscreen' do
      render_inline(component) do |c|
        c.brand { '<h4 class="title is-5 has-text-white">Bali</h4>'.html_safe }
        c.left_items([{ name: 'Tech Stack', href: '#' }])
      end

      is_expected.to have_css 'h4.title.is-5', text: 'Bali'
      is_expected.to have_css '[data-navbar-allow-transparency-value="true"]'
    end
  end

  context 'with custom burger button' do
    it 'renders navbar component with fullscreen' do
      render_inline(component) do |c|
        c.brand { '<h4 class="title is-5 has-text-white">Bali</h4>'.html_safe }
        c.burger(class: 'custom-burger')
        c.left_items([{ name: 'Tech Stack', href: '#' }])
      end

      is_expected.to have_css 'h4.title.is-5', text: 'Bali'
      is_expected.to have_css 'a.navbar-burger.burger.custom-burger'
    end
  end
end
