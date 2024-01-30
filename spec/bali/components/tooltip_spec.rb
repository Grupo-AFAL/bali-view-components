# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tooltip::Component, type: :component do
  let(:component) { Bali::Tooltip::Component.new(class: 'help-tip') }

  it 'renders a trigger with a question mark' do
    render_inline(component) do |c|
      c.with_trigger { c.tag.span '?' }
    end

    expect(page).to have_css '.trigger', text: '?'
  end
end
