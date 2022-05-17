# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Columns::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Columns::Component.new(**options) }

  subject { rendered_component }

  it 'renders' do
    render_inline(component) do |c|
      c.column do
        '<p>First</p>'
      end

      c.column do
        '<p>Second</p>'
      end
    end

    is_expected.to have_css '.columns-component.columns div'
    is_expected.to have_css 'div.column', text: 'First'
    is_expected.to have_css 'div.column', text: 'Second'
  end
end
