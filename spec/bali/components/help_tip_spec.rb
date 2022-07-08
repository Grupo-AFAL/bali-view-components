# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::HelpTip::Component, type: :component do
  let(:component) { Bali::HelpTip::Component.new }

  it 'renders a trigger with a question mark' do
    render_inline(component)

    expect(page).to have_css '.trigger', text: '?'
  end
end
