# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Level::Component, type: :component do
  let(:component) { Bali::Level::Component.new(**@options) }

  before { @options = {} }

  subject { rendered_component }

  it 'renders' do
    render_inline(component) do |c|
        c.level_left do |level|
            level.item(text: 'Left')
        end

        c.level_right do |level|
          level.item(text: 'Right')
      end
    end

    is_expected.to have_css '.level div'
    is_expected.to have_css 'div.level-item', text: 'Left'
    is_expected.to have_css 'div.level-item', text: 'Right'
  end
end
