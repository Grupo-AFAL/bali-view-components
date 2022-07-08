# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::InfoLevel::Component, type: :component do
  let(:component) { Bali::InfoLevel::Component.new(**@options) }

  before { @options = {} }

  context 'with one title' do
    it 'renders' do
      render_inline(component) do |c|
        c.item do |ci|
          ci.heading('Heading')
          ci.title('Title')
        end
      end

      expect(page).to have_css '.info-level-component'
      expect(page).to have_css '.heading', text: 'Heading'
      expect(page).to have_css '.title', text: 'Title'
    end
  end

  context 'with multiple titles' do
    it 'renders' do
      render_inline(component) do |c|
        c.item do |ci|
          ci.heading('Heading')
          ci.title('Title 1')
          ci.title('Title 2')
        end
      end

      expect(page).to have_css '.info-level-component'
      expect(page).to have_css '.heading', text: 'Heading'
      expect(page).to have_css '.title', text: 'Title 1'
      expect(page).to have_css '.title', text: 'Title 2'
    end
  end
end
