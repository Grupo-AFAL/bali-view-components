# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::BooleanIcon::Component, type: :component do
  let(:options) { { value: true } }
  let(:component) { Bali::BooleanIcon::Component.new(**options) }

  subject { rendered_component }

  it 'renders a boolean-icon component with true value' do
    render_inline(component)

    expect(subject).to have_css 'div.boolean-icon-component.has-text-success'
  end

  it 'renders a boolean-icon component with false value' do
    options[:value] = false
    render_inline(component)

    expect(subject).to have_css 'div.boolean-icon-component.has-text-danger'
  end
end
