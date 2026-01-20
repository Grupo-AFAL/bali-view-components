# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Timeago::Component, type: :component do
  let(:datetime) { 10.seconds.ago }
  let(:options) { {} }
  let(:component) { described_class.new(datetime, **options) }

  describe 'basic rendering' do
    it 'renders a time element' do
      render_inline(component)

      expect(page).to have_css('time.timeago-component')
    end

    it 'includes the Stimulus controller' do
      render_inline(component)

      expect(page).to have_css('[data-controller="timeago"]')
    end

    it 'includes the datetime value for Stimulus' do
      render_inline(component)

      expect(page).to have_css('[data-timeago-datetime-value]')
    end

    it 'includes the standard datetime HTML attribute' do
      render_inline(component)

      expect(page).to have_css('time[datetime]')
    end

    it 'sets the locale value from I18n' do
      render_inline(component)

      expect(page).to have_css('[data-timeago-locale-value="en"]')
    end
  end

  describe 'default values' do
    it 'defaults include_seconds to true' do
      render_inline(component)

      expect(page).to have_css('[data-timeago-include-seconds-value="true"]')
    end

    it 'defaults add_suffix to false' do
      render_inline(component)

      expect(page).to have_css('[data-timeago-add-suffix-value="false"]')
    end

    it 'does not include refresh_interval when not set' do
      render_inline(component)

      expect(page).to have_no_css('[data-timeago-refresh-interval-value]')
    end
  end

  describe 'with refresh_interval' do
    let(:options) { { refresh_interval: 5000 } }

    it 'includes the refresh interval value' do
      render_inline(component)

      expect(page).to have_css('[data-timeago-refresh-interval-value="5000"]')
    end
  end

  describe 'with include_seconds: false' do
    let(:options) { { include_seconds: false } }

    it 'sets include_seconds to false' do
      render_inline(component)

      expect(page).to have_css('[data-timeago-include-seconds-value="false"]')
    end
  end

  describe 'with add_suffix: true' do
    let(:options) { { add_suffix: true } }

    it 'sets add_suffix to true' do
      render_inline(component)

      expect(page).to have_css('[data-timeago-add-suffix-value="true"]')
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(datetime, class: 'custom-class'))

      expect(page).to have_css('time.timeago-component.custom-class')
    end

    it 'accepts custom data attributes' do
      render_inline(described_class.new(datetime, data: { testid: 'timeago-test' }))

      expect(page).to have_css('[data-testid="timeago-test"]')
    end

    it 'preserves custom data attributes alongside controller data' do
      render_inline(described_class.new(datetime, data: { custom: 'value' }))

      expect(page).to have_css('[data-custom="value"]')
      expect(page).to have_css('[data-controller="timeago"]')
    end

    it 'accepts arbitrary HTML attributes' do
      render_inline(described_class.new(datetime, id: 'my-timeago', title: 'Last updated'))

      expect(page).to have_css('time#my-timeago[title="Last updated"]')
    end
  end

  describe 'with different datetime types' do
    it 'handles Time objects' do
      render_inline(described_class.new(Time.current))

      expect(page).to have_css('time[datetime]')
    end

    it 'handles DateTime objects' do
      render_inline(described_class.new(DateTime.current))

      expect(page).to have_css('time[datetime]')
    end

    it 'handles ActiveSupport::TimeWithZone' do
      render_inline(described_class.new(Time.current.in_time_zone('UTC')))

      expect(page).to have_css('time[datetime]')
    end
  end

  describe 'i18n support' do
    it 'uses Spanish locale when set' do
      I18n.with_locale(:es) do
        render_inline(component)

        expect(page).to have_css('[data-timeago-locale-value="es"]')
      end
    end
  end

  describe 'constants' do
    it 'has BASE_CLASSES constant' do
      expect(described_class::BASE_CLASSES).to eq('timeago-component')
    end

    it 'has CONTROLLER constant' do
      expect(described_class::CONTROLLER).to eq('timeago')
    end
  end
end
