# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::ActionsDropdown::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::ActionsDropdown::Component.new(**options) }

  it 'renders actionsdropdown component' do
    render_inline(component) do |c|
      c.tag.span('test')
    end

    expect(page).to have_css 'div.actions-dropdown-component'
  end
end
