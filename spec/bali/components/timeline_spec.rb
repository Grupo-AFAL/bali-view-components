# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Timeline::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Timeline::Component.new(**options) }

  it 'renders timeline component' do
    render_inline(component)

    expect(page).to have_css 'div.timeline-component'
  end

  it 'renders timeline center aligned' do
    options[:position] = :center
    render_inline(component)

    expect(page).to have_css 'div.timeline-component.is-centered'
  end

  it 'renders timeline right aligned' do
    options[:position] = :right
    render_inline(component)

    expect(page).to have_css 'div.timeline-component.is-rtl'
  end

  it 'renders timeline items with icons' do
    render_inline(component) do |c|
      c.with_tag_item(icon: 'alert')
    end

    expect(page).to have_css '.timeline-item', count: 1
    expect(page).to have_css '.timeline-marker.is-icon'
  end

  it 'renders timeline items with heading' do
    render_inline(component) do |c|
      c.with_tag_item(heading: 'January 2022')
    end

    expect(page).to have_css '.timeline-item', count: 1
    expect(page).to have_css '.timeline-content .heading', text: 'January 2022'
  end

  it 'renders timeline header' do
    render_inline(component) do |c|
      c.with_tag_header(text: 'Start')
    end

    expect(page).to have_css '.timeline-header', count: 1
    expect(page).to have_css '.timeline-header .badge', text: 'Start'
  end

  it 'renders timeline header with tag_class' do
    render_inline(component) do |c|
      c.with_tag_header(text: 'Start', tag_class: 'badge-primary')
    end

    expect(page).to have_css '.timeline-header', count: 1
    expect(page).to have_css '.timeline-header .badge.badge-primary', text: 'Start'
  end
end
