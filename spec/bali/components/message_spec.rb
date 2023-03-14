# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Message::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Message::Component.new(**options) }

  it 'renders message component' do
    render_inline(component) do
      'Message content'
    end

    expect(page).to have_css 'div.message-component .message-body', text: 'Message content'
  end
end
