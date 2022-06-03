# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Link::Component, type: :component do
  let(:component) { Bali::Link::Component.new(**@options) }

  before { @options = { name: 'Click me!', href: '#' } }

  subject { rendered_component }

  context 'default' do
    it 'renders' do
      render_inline(component)

      is_expected.to have_css 'a.button', text: 'Click me!'
      is_expected.to have_css 'a[href="#"]'
    end
  end

  %i[primary secondary success danger warning].each do |button_type|
    context "#{button_type} button type" do
      before { @options.merge!(type: button_type) }

      it 'renders' do
        render_inline(component)

        is_expected.to have_css "a.button.is-#{button_type}", text: 'Click me!'
        is_expected.to have_css 'a[href="#"]'
      end
    end
  end

  context 'with icon' do
    it 'renders' do
      render_inline(component) do |c|
        c.icon(class: 'icon') do
          '<svg></svg>'.html_safe
        end
      end

      is_expected.to have_css 'a.button', text: 'Click me!'
      is_expected.to have_css 'a[href="#"]'
      is_expected.to have_css 'span.icon'
    end
  end
end
