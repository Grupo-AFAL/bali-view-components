# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tabs::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Tabs::Component.new(**options) }

  it 'renders tabs with content' do
    render_inline(component) do |c|
      c.with_tab(title: 'Tab 1', active: true) { '<p>Tab 1 content</p>'.html_safe }
      c.with_tab(title: 'Tab 2') { '<p>Tab 2 content</p>'.html_safe }
    end

    expect(page).to have_css '.tabs-component'
    expect(page).to have_css 'li.tab-active', text: 'Tab 1'
    expect(page).to have_css 'li', text: 'Tab 2'
    expect(page).to have_css 'p', text: 'Tab 1 content'
    expect(page).to have_css '.hidden p', text: 'Tab 2 content'
  end

  it 'renders tabs with class centered' do
    options.merge!(tabs_class: 'is-centered')
    render_inline(component)

    expect(page).to have_css 'div.tabs.is-centered'
  end

  it 'renders tabs with icon' do
    render_inline(component) do |c|
      c.with_tab(title: 'Tab', active: true, icon: 'alert') { '<p>Tab content</>'.html_safe }
    end

    expect(page).to have_css 'span.icon-component svg'
  end

  context 'when a tab has href' do
    it 'renders tabs with href' do
      render_inline(component) do |c|
        c.with_tab(title: 'Tab', href: '/')
      end

      expect(page).to have_css 'a[href="/"]'
    end
  end
end
