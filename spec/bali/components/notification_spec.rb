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

    it 'renders close button with i18n aria-label' do
      render_inline(described_class.new)

      expect(page).to have_css 'button[data-action="notification#close"]'
      expect(page).to have_css 'button[aria-label="Close notification"]'
    end

    it 'renders base classes' do
      render_inline(described_class.new(fixed: false))

      expect(page).to have_css 'div.notification-component.alert'
    end
  end

  describe 'types' do
    described_class::TYPES.each_key do |type|
      next if %i[danger primary].include?(type) # aliases

      it "renders #{type} type" do
        render_inline(described_class.new(type: type, fixed: false))

        expect(page).to have_css "div.alert.#{described_class::TYPES[type]}"
      end
    end

    it 'maps danger to error' do
      render_inline(described_class.new(type: :danger, fixed: false))

      expect(page).to have_css 'div.alert.alert-error'
    end

    it 'maps primary to info' do
      render_inline(described_class.new(type: :primary, fixed: false))

      expect(page).to have_css 'div.alert.alert-info'
    end

    it 'falls back to success for unknown types' do
      render_inline(described_class.new(type: :unknown, fixed: false))

      expect(page).to have_css 'div.alert.alert-success'
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

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(fixed: false, class: 'my-custom-class'))

      expect(page).to have_css 'div.notification-component.my-custom-class'
    end
  end

  describe 'constants' do
    it 'has frozen TYPES constant' do
      expect(described_class::TYPES).to be_frozen
    end

    it 'has BASE_CLASSES constant' do
      expect(described_class::BASE_CLASSES).to eq('notification-component alert')
    end
  end
end
