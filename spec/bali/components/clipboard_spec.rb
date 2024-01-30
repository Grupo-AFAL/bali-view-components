# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Clipboard::Component, type: :component do
  let(:component) { Bali::Clipboard::Component.new(**@options) }

  before { @options = {} }

  it 'renders clipboard component' do
    render_inline(component) do |c|
      c.with_trigger('Copy')
      c.with_source('Click button to copy me!')
    end

    expect(page).to have_css 'div.clipboard-component'
    expect(page).to have_css 'div.clipboard-component[data-controller="clipboard"]'

    expect(page).to have_css 'button.clipboard-trigger', text: 'Copy'
    expect(page).to have_css 'button.clipboard-trigger[data-clipboard-target="button"]'
    expect(page).to have_css 'button.clipboard-trigger[data-action="click->clipboard#copy"]'

    expect(page).to have_css 'div.clipboard-source', text: 'Click button to copy me!'
    expect(page).to have_css 'div.clipboard-source[data-clipboard-target="source"]'
  end
end
