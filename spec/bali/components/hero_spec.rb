# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Hero::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Hero::Component.new(**options) }

  it 'renders hero component' do
    render_inline(component) do |c|
      c.title('Titulo')
      c.subtitle('Subtitulo')
    end

    expect(page).to have_css 'p.title', text: 'Titulo'
    expect(page).to have_css 'p.subtitle', text: 'Subtitulo'
  end
end
