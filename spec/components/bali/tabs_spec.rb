# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tabs::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Tabs::Component.new(**options) }

  subject { rendered_component }

  it 'renders tabs with content' do
    render_inline(component) do |c|
      c.tab(title: 'Tab 1', active: true) { '<p>Tab 1 content</p>'.html_safe }
      c.tab(title: 'Tab 2') { '<p>Tab 2 content</p>'.html_safe }
    end

    expect(rendered_component).to have_css 'li.is-active', text: 'Tab 1'
    expect(rendered_component).to have_css 'li', text: 'Tab 2'
    expect(rendered_component).to have_css 'p', text: 'Tab 1 content'
    expect(rendered_component).to have_css '.is-hidden p', text: 'Tab 2 content'
  end

  it 'renders tabs with class centered' do
    options.merge!(class: 'is-centered')
    render_inline(component)

    expect(rendered_component).to have_css 'div.tabs.is-centered'
  end

  it 'renders tabs with icon' do
    render_inline(component) do |c|
      c.tab(title: 'Tab', active: true, icon: 'alert') { '<p>Tab content</>'.html_safe }
    end

    expect(rendered_component).to have_css 'span.icon svg'
  end
end
