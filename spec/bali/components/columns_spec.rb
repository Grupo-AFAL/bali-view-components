# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Columns::Component, type: :component do
  let(:component) { Bali::Columns::Component.new }

  it 'renders' do
    render_inline(component) do |c|
      c.with_column do
        '<p>First</p>'
      end

      c.with_column do
        '<p>Second</p>'
      end
    end

    expect(page).to have_css '.columns-component.flex div'
    expect(page).to have_css 'div.column', text: 'First'
    expect(page).to have_css 'div.column', text: 'Second'
  end
end
