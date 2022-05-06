# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tabs::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Tabs::Component.new(**options) }

  subject { rendered_component }

  it 'renders' do
    render_inline(component)

    expect(subject).to have_css 'div'
  end
end
