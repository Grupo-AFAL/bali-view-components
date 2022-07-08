# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tag::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Tag::Component.new(**options) }

  subject { page }

  it 'renders tag component' do
    render_inline(component)

    expect(subject).to have_css 'div.tag-component'
  end
end
