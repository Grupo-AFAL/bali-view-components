# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Progress::Component, type: :component do
  let(:options) { { value: nil, color: nil } }
  let(:component) { Bali::Progress::Component.new(**options) }

  it 'renders progress component' do
    render_inline(component)

    expect(page).to have_css 'div.progress-component'
  end
end
