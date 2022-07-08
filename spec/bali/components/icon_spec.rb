# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Icon::Component, type: :component do
  let(:component) { Bali::Icon::Component.new('snowflake', **@options) }

  before { @options = {} }

  it 'renders' do
    render_inline(component)

    expect(page).to have_css 'span.icon'
  end

  it 'renders with an id and additional classes' do
    @options.merge!(id: 'my-icon', class: 'has-text-info')
    render_inline(component)

    expect(page).to have_css 'span.icon.has-text-info'
    expect(page).to have_css 'span[id="my-icon"]'
  end
end
