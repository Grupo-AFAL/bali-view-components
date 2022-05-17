# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::InfoLevel::Component, type: :component do
  let(:component) { Bali::InfoLevel::Component.new(**@options) }

  before { @options = {} }

  subject { rendered_component }

  it 'renders' do
    render_inline(component) do |c|
      c.item(
        heading: 'Heading',
        title: 'Title',
        options: { title_class: 'title is-6' }
      )
    end

    expect(subject).to have_css '.info-level-component'
    expect(subject).to have_css '.heading', text: 'Heading'
    expect(subject).to have_css '.title', text: 'Title'
  end
end
