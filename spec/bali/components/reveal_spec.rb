# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Reveal::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Reveal::Component.new(**options) }

  subject { page }

  it 'renders reveal component' do
    render_inline(component)

    expect(subject).to have_css 'div.reveal-component'
  end
end
