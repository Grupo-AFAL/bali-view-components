# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Link::Component, type: :component do
  ICON = '<svg width="13" height="13" viewBox="0 0 13 13" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path fill-rule="evenodd" clip-rule="evenodd" d="M12.1728 2.75329C12.4328 3.01329 12.4328 3.43329 12.1728 3.69329L10.9528 4.91329L8.4528 2.41329L9.6728 1.19329C9.9328 0.933291 10.3528 0.933291 10.6128 1.19329L12.1728 2.75329ZM0.366211 12.9999V10.4999L7.73954 3.12655L10.2395 5.62655L2.86621 12.9999H0.366211Z" fill="#00AA92"/>
          </svg>'.html_safe

  let(:component) { Bali::Link::Component.new(**@options) }

  before { @options = { name: 'Click me!', href: '#' } }

  subject { rendered_component }

  describe 'rendering' do
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
            ICON
          end
        end

        is_expected.to have_css 'a.button', text: 'Click me!'
        is_expected.to have_css 'a[href="#"]'
        is_expected.to have_css 'span.icon'
      end
    end
  end
end
