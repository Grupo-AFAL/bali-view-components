# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::HoverCard::Component, type: :component do
  let(:component) { Bali::HoverCard::Component.new(**@options) }

  before { @options = {} }

  subject { rendered_component }

  describe 'render' do
    context 'with template' do
      it 'renders' do
        render_inline(component) do |c|
          c.template do
            '<p>Cuerpo</p>'.html_safe
          end
        end

        is_expected.to have_css 'div.hovercard-component'
        is_expected.to include "data-hovercard-target='template'"
        is_expected.to include 'Cuerpo'
      end
    end

    context 'with hover url' do
      before { @options.merge!(url: '/aviso-de-privacidad') }

      it 'renders' do
        render_inline(component)

        is_expected.to have_css 'div.hovercard-component'
        is_expected.not_to include "data-hovercard-target='template'"
      end
    end
  end
end
