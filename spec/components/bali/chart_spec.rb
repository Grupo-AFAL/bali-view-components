# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Chart::Component, type: :component do
  let(:component) { Bali::Chart::Component.new(**@options) }

  before { @options = {} }

  subject { rendered_component }

  it 'renders' do
    @options.merge!(data: { chocolate: 3 }, title: 'Chocolate Sales', id: 'chocolate-sales')
    render_inline(component)

    is_expected.to have_css 'div'
    is_expected.to have_css 'h3.title', text: 'Chocolate Sales'
    is_expected.to have_css 'canvas'
  end
end
