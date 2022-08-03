# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::HoverCard::Component, type: :component do
  let(:component) { Bali::HoverCard::Component.new(**@options) }

  before { @options = {} }

  describe 'render' do
    context 'with template' do
      it 'renders' do
        render_inline(component) do |c|
          c.template do
            '<p>Cuerpo</p>'.html_safe
          end
        end

        expect(page).to have_css 'div.hover-card-component'

        expect(rendered_content).to include "data-hovercard-target='template'"
        expect(rendered_content).to include 'Cuerpo'
      end
    end

    context 'with hover url' do
      before { @options.merge!(url: '/aviso-de-privacidad') }

      it 'renders' do
        render_inline(component)

        expect(page).to have_css 'div.hover-card-component'
        expect(rendered_content).not_to include "data-hovercard-target='template'"
      end
    end

    context 'with open_on_click option' do
      before { @options.merge!(open_on_click: true) }

      it 'renders' do
        render_inline(component)

        expect(page).to have_css 'div.hover-card-component'
        expect(rendered_content).to include 'hovercard-open-on-click-value="true"'
      end
    end
  end
end
