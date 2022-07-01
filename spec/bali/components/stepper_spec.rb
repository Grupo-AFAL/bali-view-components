# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Stepper::Component, type: :component do
  let(:options) { { current: nil } }
  let(:component) { Bali::Stepper::Component.new(**options) }

  subject { rendered_component }

  it 'renders stepper component' do
    render_inline(component)

    expect(subject).to have_css 'div.stepper-component'
  end
end
