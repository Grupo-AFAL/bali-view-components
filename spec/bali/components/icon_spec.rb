# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Icon::Component, type: :component do
  let(:component) { Bali::Icon::Component.new('snowflake', **@options) }

  before { @options = {} }

  it 'renders' do
    render_inline(component)

    expect(page).to have_css 'span.icon-component'
  end

  it 'renders with an id and additional classes' do
    @options.merge!(id: 'my-icon', class: 'text-info')
    render_inline(component)

    expect(page).to have_css 'span.icon-component.text-info'
    expect(page).to have_css 'span[id="my-icon"]'
  end

  it 'renders with size classes' do
    component = Bali::Icon::Component.new('snowflake', size: :large)
    render_inline(component)

    expect(page).to have_css 'span.icon-component.size-12'
  end
end
