# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Timeline::Component, type: :component do
  let(:options) { {  } }
  let(:component) { Bali::Timeline::Component.new(**options) }

  subject { page }

  it 'renders timeline component' do
    render_inline(component)

    expect(subject).to have_css 'div.timeline-component'
  end
end
