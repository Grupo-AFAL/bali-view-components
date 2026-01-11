# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Notification::Component, type: :component do
  describe 'basic rendering' do
    it 'renders alert with default success type' do
      render_inline(described_class.new) do
        'Hello World!'
      end

      expect(page).to have_css 'div.notification-component.alert', text: 'Hello World!'
      expect(page).to have_css 'div.alert-success'
    end

    it 'renders with stimulus controller' do
      render_inline(described_class.new)

      expect(page).to have_css '[data-controller="notification"]'
      expect(page).to have_css '[data-notification-delay-value="3000"]'
      expect(page).to have_css '[data-notification-dismiss-value="true"]'
    end

    it 'renders close button' do
      render_inline(described_class.new)

      expect(page).to have_css 'button[data-action="notification#close"]'
    end
  end

  describe 'types' do
    %i[success info warning error].each do |type|
      it "renders #{type} type" do
        render_inline(described_class.new(type: type, fixed: false))

        expect(page).to have_css "div.alert.alert-#{type}"
      end
    end

    it 'maps danger to error' do
      render_inline(described_class.new(type: :danger, fixed: false))

      expect(page).to have_css 'div.alert.alert-error'
    end
  end

  describe 'fixed positioning' do
    it 'renders fixed classes when fixed is true' do
      render_inline(described_class.new(fixed: true))

      expect(page).to have_css 'div.alert.fixed'
    end

    it 'does not render fixed classes when fixed is false' do
      render_inline(described_class.new(fixed: false))

      expect(page).not_to have_css 'div.fixed'
    end
  end

  describe 'dismiss configuration' do
    it 'sets dismiss value to true' do
      render_inline(described_class.new(dismiss: true))

      expect(page).to have_css '[data-notification-dismiss-value="true"]'
    end

    it 'sets dismiss value to false' do
      render_inline(described_class.new(dismiss: false))

      expect(page).to have_css '[data-notification-dismiss-value="false"]'
    end
  end

  describe 'custom delay' do
    it 'sets custom delay value' do
      render_inline(described_class.new(delay: 5000))

      expect(page).to have_css '[data-notification-delay-value="5000"]'
    end
  end
end
