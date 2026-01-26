# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::LabelValue::Component, type: :component do
  it 'renders with label and value' do
    render_inline(described_class.new(label: 'Name', value: 'Juan Perez'))

    expect(page).to have_css 'label', text: 'Name'
    expect(page).to have_css 'div.min-h-6', text: 'Juan Perez'
  end

  it 'renders with block content instead of value' do
    render_inline(described_class.new(label: 'URL')) do
      'Custom link content'
    end

    expect(page).to have_css 'div.min-h-6', text: 'Custom link content'
  end

  it 'prefers value over block content when both provided' do
    render_inline(described_class.new(label: 'Name', value: 'From value')) do
      'From block'
    end

    expect(page).to have_css 'div.min-h-6', text: 'From value'
    expect(page).not_to have_text 'From block'
  end

  it 'merges custom classes' do
    render_inline(described_class.new(label: 'Name', value: 'Test', class: 'custom-class'))

    expect(page).to have_css 'div.mb-2.custom-class'
  end

  it 'passes through HTML attributes' do
    render_inline(described_class.new(label: 'Name', value: 'Test', data: { testid: 'lv' }))

    expect(page).to have_css '[data-testid="lv"]'
  end

  it 'applies proper label styling' do
    render_inline(described_class.new(label: 'Name', value: 'Test'))

    expect(page).to have_css 'label.font-bold.text-xs'
  end

  it 'applies value container styling' do
    render_inline(described_class.new(label: 'Name', value: 'Test'))

    expect(page).to have_css 'div.min-h-6', text: 'Test'
  end
end
