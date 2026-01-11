# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Loader::Component, type: :component do
  let(:component) { Bali::Loader::Component.new(**@options) }

  before { @options = {} }

  it 'renders loader with default options' do
    render_inline(component)

    expect(page).to have_css 'div.loader-component'
    expect(page).to have_css 'span.loading.loading-spinner.loading-lg'
    expect(page).to have_css 'h2.text-xl.font-semibold.text-center', text: 'Loading...'
  end

  it 'renders loader with custom text' do
    @options.merge!(text: 'Cargando')

    render_inline(component)

    expect(page).to have_css 'div.loader-component'
    expect(page).to have_css 'h2.text-xl.font-semibold.text-center', text: 'Cargando'
  end
end
