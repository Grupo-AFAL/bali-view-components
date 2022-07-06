# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Notification::Component, type: :component do
  let(:component) { described_class }

  subject { page }

  context 'default' do
    it 'renders success component with default values' do
      render_inline(component.new) do
        'Hello World!'
      end

      is_expected.to have_css 'div.notification-component', text: 'Hello World!'
      is_expected.to have_css 'div.notification.fixed'
      is_expected.to have_css 'div.is-success'
      is_expected.to have_css 'div[data-controller="notification"]'
      is_expected.to have_css 'div[data-notification-dismiss-value="true"]'
      is_expected.to have_css 'div[data-notification-delay-value="3000"]'
      is_expected.to have_css 'button[data-action="notification#close"]'
      is_expected.to have_css 'button.delete'
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

        is_expected.to have_css 'div.notification', text: 'Hello World!'
        is_expected.not_to have_css 'div.fixed'
        is_expected.to have_css 'div[data-notification-dismiss-value="false"]'
        is_expected.to have_css 'div[data-notification-delay-value="1000"]'
        is_expected.to have_css "div.is-#{notification_type}"
        is_expected.to have_css 'button.delete'
      end
    end
  end
end
