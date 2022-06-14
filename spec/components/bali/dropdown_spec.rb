# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Dropdown::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Dropdown::Component.new(**options) }

  subject { rendered_component }

  it 'renders dropdown with options' do
    render_inline(component) do |c|
      c.trigger(class: 'button') { 'Trigger' }

      c.tag.ul do
        c.tag.li('Item')
      end
    end

    expect(subject).to have_css 'div'
  end
end
