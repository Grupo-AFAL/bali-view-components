# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tags::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Tags::Component.new(**options) }

  subject { page }

  it 'renders tags component' do
    render_inline(component)

    expect(subject).to have_css 'div.tags-component'
  end
end
