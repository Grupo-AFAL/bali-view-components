# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::ImageGrid::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::ImageGrid::Component.new(**options) }

  subject { page }

  it 'renders' do
    render_inline(component)

    expect(subject).to have_css 'div'
  end
end
