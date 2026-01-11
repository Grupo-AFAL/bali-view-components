# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Progress::Component, type: :component do
  describe 'basic rendering' do
    it 'renders progress component with DaisyUI classes' do
      render_inline(described_class.new(value: 50))

      expect(page).to have_css 'div.progress-component'
      expect(page).to have_css 'progress.progress.w-full[value="50"][max="100"]'
    end

    it 'renders percentage by default' do
      render_inline(described_class.new(value: 75))

      expect(page).to have_css 'span', text: '75%'
    end

    it 'hides percentage when show_percentage is false' do
      render_inline(described_class.new(value: 50, show_percentage: false))

      expect(page).not_to have_css 'span'
    end
  end

  describe 'colors' do
    %i[primary secondary accent neutral info success warning error].each do |color|
      it "renders #{color} color" do
        render_inline(described_class.new(value: 50, color: color))

        expect(page).to have_css "progress.progress.progress-#{color}"
      end
    end
  end

  describe 'percentage calculation' do
    it 'calculates percentage from value and max' do
      render_inline(described_class.new(value: 25, max: 50))

      expect(page).to have_css 'span', text: '50%'
    end

    it 'handles zero max without error' do
      render_inline(described_class.new(value: 25, max: 0))

      expect(page).to have_css 'span', text: '0%'
    end
  end
end
