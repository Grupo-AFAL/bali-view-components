# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::SwappableIcons::Component, type: :component do
  let(:component) { Bali::SwappableIcons::Component.new }

  it 'renders SwappableIcons component' do
    render_inline(component) do |c|
      c.main_icon('handle')
      c.secondary_icon('handle-alt')
    end

    expect(page).to have_css 'div.swappable-icons-component'
    expect(page).to have_css 'span.icon-component.main-icon'
    expect(page).to have_css 'span.icon-component.secondary-icon'
  end
end
