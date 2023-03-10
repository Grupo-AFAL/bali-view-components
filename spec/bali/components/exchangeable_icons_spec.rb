# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::ExchangeableIcons::Component, type: :component do
  let(:component) { Bali::ExchangeableIcons::Component.new }

  it 'renders exchangeableicons component' do
    render_inline(component) do |c|
      c.main_icon('handle')
      c.secondary_icon('handle-alt')
    end

    expect(page).to have_css 'div.exchangeable-icons-component'
    expect(page).to have_css 'span.icon-component.main-icon'
    expect(page).to have_css 'span.icon-component.secondary-icon'
  end
end
