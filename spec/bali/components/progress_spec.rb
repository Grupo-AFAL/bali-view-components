# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Progress::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Progress::Component.new(**options) }

  it 'renders progress component' do
    render_inline(component)

    expect(page).to have_css 'div.progress-component > progress'
  end

  context 'when no color code is given' do
    it 'renders progress bar with default color' do
      render_inline(component)

      expect(page).to have_css 'progress[style="--progress-value-bar-color: hsl(196, 82%, 78%);"]'
    end
  end

  context 'when custom color code is given' do
    before { options.merge!(color_code: '#52BE80') }

    it 'renders progress bar with default color' do
      render_inline(component)

      expect(page).to have_css 'progress[style="--progress-value-bar-color: #52BE80;"]'
    end
  end

  context 'when display percentage is enabled' do
    before { options.merge!(value: 75) }
    it 'renders percentage value' do
      render_inline(component)

      expect(page).to have_css 'small'
    end
  end

  context 'when display percentage is disabled' do
    before { options.merge!(value: 35, percentage: false) }

    it 'renders percentage value' do
      render_inline(component)

      expect(page).not_to have_css 'small'
    end
  end
end
