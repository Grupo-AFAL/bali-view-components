# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::HelloButton::Component, type: :component do
  let(:options) { { label: nil } }
  let(:component) { Bali::HelloButton::Component.new(**options) }

  it 'renders hellobutton component' do
    render_inline(component)

    expect(page).to have_css 'div.hello-button-component'
  end
end
