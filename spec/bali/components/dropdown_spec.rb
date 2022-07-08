# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Dropdown::Component, type: :component do
  let(:component) { Bali::Dropdown::Component.new }

  before do
    render_inline(component) do |c|
      c.trigger(class: 'button') { 'Trigger' }

      c.tag.ul do
        c.tag.li('Item', class: 'dropdown-item')
      end
    end
  end

  it 'renders dropdown with options' do
    expect(page).to have_css '.dropdown-item'
  end

  it 'renders dropdown and check trigger' do
    expect(page).to have_css '.button', text: 'Trigger'
  end
end
