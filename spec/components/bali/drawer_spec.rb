# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bali::Drawer::Component, type: :component do
  let(:component) { Bali::Drawer::Component.new(**@options) }

  before { @options = {} }

  subject { rendered_component }

  it 'renders when active is true' do
    @options.merge!(active: true)
    render_inline(component)

    is_expected.to have_css 'div.drawer.is-active'
  end

  it 'renders when active is false' do
    render_inline(component)

    is_expected.to have_css 'div.drawer'
  end

  it 'renders with custom content' do
    render_inline(component) do
      '<p>Hello World!</p>'.html_safe
    end

    is_expected.to have_css 'p', text: 'Hello World!'
  end

  it 'renders with custom class' do
    @options.merge!(class: 'custom-class')
    render_inline(component) do
      '<p>Hello World!</p>'.html_safe
    end

    is_expected.to have_css 'div.drawer-component.custom-class', text: 'Hello World!'
  end
end
