# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FlashNotifications::Component, type: :component do
  describe 'rendering' do
    context 'without notice and alert' do
      it 'does not render any notification' do
        render_inline(described_class.new)

        expect(page).not_to have_css 'div.notification-component'
      end
    end

    context 'with notice' do
      it 'renders a success notification' do
        render_inline(described_class.new(notice: 'This is a notice'))

        expect(page).to have_css 'div.notification-component.alert-success',
                                 text: 'This is a notice'
      end
    end

    context 'with alert' do
      it 'renders an error notification' do
        render_inline(described_class.new(alert: 'This is an alert'))

        expect(page).to have_css 'div.notification-component.alert-error', text: 'This is an alert'
      end
    end

    context 'with both notice and alert' do
      it 'renders both notifications' do
        render_inline(described_class.new(notice: 'Success message', alert: 'Error message'))

        expect(page).to have_css 'div.alert-success', text: 'Success message'
        expect(page).to have_css 'div.alert-error', text: 'Error message'
      end
    end
  end

  describe 'flash type mapping' do
    it 'maps notice to success type' do
      render_inline(described_class.new(notice: 'Good news'))

      expect(page).to have_css '.alert-success'
      expect(page).not_to have_css '.alert-error'
    end

    it 'maps alert to error type' do
      render_inline(described_class.new(alert: 'Bad news'))

      expect(page).to have_css '.alert-error'
      expect(page).not_to have_css '.alert-success'
    end
  end
end
