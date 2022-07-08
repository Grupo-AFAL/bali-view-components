# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Notification::Component, type: :component do
  let(:component) { described_class }

  context 'default' do
    it 'renders success component with default values' do
      render_inline(component.new) do
        'Hello World!'
      end

      expect(page).to have_css 'div.notification-component', text: 'Hello World!'
      expect(page).to have_css 'div.notification.fixed'
      expect(page).to have_css 'div.is-success'
      expect(page).to have_css 'div[data-controller="notification"]'
      expect(page).to have_css 'div[data-notification-dismiss-value="true"]'
      expect(page).to have_css 'div[data-notification-delay-value="3000"]'
      expect(page).to have_css 'button[data-action="notification#close"]'
      expect(page).to have_css 'button.delete'
    end
  end

  %i[success info warning danger info primary].each do |notification_type|
    context "#{notification_type} notification type" do
      it 'renders' do
        render_inline(component.new(
                        type: notification_type, fixed: false, dismiss: false, delay: 1000
                      )) do
          'Hello World!'
        end

        expect(page).to have_css 'div.notification', text: 'Hello World!'
        expect(page).not_to have_css 'div.fixed'
        expect(page).to have_css 'div[data-notification-dismiss-value="false"]'
        expect(page).to have_css 'div[data-notification-delay-value="1000"]'
        expect(page).to have_css "div.is-#{notification_type}"
        expect(page).to have_css 'button.delete'
      end
    end
  end
end
