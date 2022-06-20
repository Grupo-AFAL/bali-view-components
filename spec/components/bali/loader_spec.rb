# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Loader::Component, type: :component do
  let(:component) { Bali::Loader::Component.new(**@options) }

  before { @options = { text: 'Cargando...' } }

  subject { rendered_component }

  it 'renders loader with default options' do
    render_inline(component)
    expect(rendered_component).to have_css('div.loader-component')
    expect(rendered_component).to have_css('h2.title.is-4.has-text-centered'), text: 'Cargando...'
  end

  it 'renders loader with custom text' do
    @options.merge!(text: :Loading)

    render_inline(component)
    expect(rendered_component).to have_css('div.loader-component')
    expect(rendered_component).to have_css('h2.title.is-4.has-text-centered'), text: 'Loading'
  end
end
