# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Timeago::Component, type: :component do
  let(:component) { Bali::Timeago::Component.new(10.seconds.ago, **@options) }

  before { @options = {} }

  it 'renders timeago component' do
    render_inline(component)

    expect(page).to have_css 'time.timeago-component'
    expect(page).to have_css '[data-controller="timeago"]'
  end

  context 'with refresh interval value' do
    before { @options.merge!(refresh_interval: 100) }

    it 'renders timeago component' do
      render_inline(component)

      expect(page).to have_css 'time.timeago-component'
      expect(page).to have_css '[data-timeago-refresh-interval-value="100"]'
    end
  end

  context 'with include seconds value' do
    before { @options.merge!(include_seconds: false) }

    it 'renders timeago component' do
      render_inline(component)

      expect(page).to have_css 'time.timeago-component'
      expect(page).to have_css '[data-timeago-include-second-value="false"]'
    end
  end
end
