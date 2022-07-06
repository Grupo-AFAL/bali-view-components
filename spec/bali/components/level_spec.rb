# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Level::Component, type: :component do
  let(:component) { Bali::Level::Component.new }

  subject { page }

  it 'renders' do
    render_inline(component) do |c|
      c.left do |level|
        level.item(text: 'Left')
      end

      c.right do |level|
        level.item(text: 'Right')
      end
    end

    is_expected.to have_css '.level div'
    is_expected.to have_css 'div.level-item', text: 'Left'
    is_expected.to have_css 'div.level-item', text: 'Right'
  end

  context 'with level items' do
    it 'renders' do
      render_inline(component) do |c|
        c.item(text: 'Item 1')

        c.item { '<h1>Item 2</h1>'.html_safe }
      end

      is_expected.to have_css '.level div'
      is_expected.to have_css 'div.level-item', text: 'Item 1'
      is_expected.to have_css 'div.level-item', text: 'Item 2'
    end
  end
end
