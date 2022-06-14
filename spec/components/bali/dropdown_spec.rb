# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Dropdown::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Dropdown::Component.new(**options) }
  before {
    render_inline(component) do |c|
      c.trigger(class: 'button') { 'Trigger' }

      c.tag.ul do
        c.tag.li('Item', class: 'dropdown-item')
      end
    end
  }

  subject { rendered_component }

  it 'renders dropdown with options' do
    expect(subject).to have_css '.dropdown-item'
  end
  
  it 'renders dropdown and check trigger' do
    expect(subject).to have_css '.button', text: 'Trigger'
  end
end
