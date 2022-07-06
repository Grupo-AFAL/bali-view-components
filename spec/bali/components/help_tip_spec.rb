# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::HelpTip::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::HelpTip::Component.new(**options) }

  subject { page }

  it 'renders a trigger with a question mark' do
    render_inline(component)

    is_expected.to have_css '.trigger', text: '?'
  end
end
