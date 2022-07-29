# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Reveal::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Reveal::Component.new(**options) }

  it 'renders with hidden content' do
    render_inline(component)

    expect(page).to have_css 'div.reveal-component'
    expect(page).not_to have_css 'div.reveal-component.is-revealed'
  end

  it 'renders with opened content' do
    options[:opened] = true
    render_inline(component)

    expect(page).to have_css 'div.reveal-component'
    expect(page).to have_css 'div.reveal-component.is-revealed'
  end

  it 'renders trigger' do
    render_inline(component) do |c|
      c.trigger(title: 'Click here', title_class: 'reveal-title')
    end

    expect(page).to have_css 'div.reveal-trigger[data-action="click->reveal#toggle"]'
    expect(page).to have_css 'div.reveal-title', text: 'Click here'
    expect(page).to have_css '.icon-component'
  end

  it 'renders border at bottom' do
    render_inline(component) do |c|
      c.trigger(title: 'Click here', title_class: 'reveal-title')
    end

    expect(page).to have_css 'div.is-border-bottom'
  end

  it 'does not render border at bottom' do
    render_inline(component) do |c|
      c.trigger(title: 'Click here', border: false)
    end

    render_inline(component)

    expect(page).not_to have_css 'div.is-border-bottom'
  end
end
