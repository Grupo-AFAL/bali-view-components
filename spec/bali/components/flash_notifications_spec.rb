# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FlashNotifications::Component, type: :component do
  let(:component) { Bali::FlashNotifications::Component.new(**@options) }

  before { @options = {} }

  describe 'render' do
    context 'without notice and alert' do
      it 'does not render a notification component' do
        render_inline(component)

        expect(page).not_to have_css 'div.notification-component'
      end
    end

    context 'with notice' do
      before { @options[:notice] = 'This is a notice' }

      it 'renders a notification component' do
        render_inline(component)

        expect(page).to have_css 'div.notification-component.is-success', text: 'This is a notice'
      end
    end

    context 'with alert' do
      before { @options[:alert] = 'This is an alert' }

      it 'renders a notification component' do
        render_inline(component)

        expect(page).to have_css 'div.notification-component.is-danger', text: 'This is an alert'
      end
    end
  end
end
