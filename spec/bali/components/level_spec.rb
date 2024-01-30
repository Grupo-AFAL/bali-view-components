# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Level::Component, type: :component do
  let(:component) { Bali::Level::Component.new }

  it 'renders' do
    render_inline(component) do |c|
      c.with_left do |level|
        level.with_item(text: 'Left')
      end

      c.with_right do |level|
        level.with_item(text: 'Right')
      end
    end

    expect(page).to have_css '.level div'
    expect(page).to have_css 'div.level-item', text: 'Left'
    expect(page).to have_css 'div.level-item', text: 'Right'
  end

  context 'with level items' do
    it 'renders' do
      render_inline(component) do |c|
        c.with_item(text: 'Item 1')

        c.with_item { '<h1>Item 2</h1>'.html_safe }
      end

      expect(page).to have_css '.level div'
      expect(page).to have_css 'div.level-item', text: 'Item 1'
      expect(page).to have_css 'div.level-item', text: 'Item 2'
    end
  end
end
