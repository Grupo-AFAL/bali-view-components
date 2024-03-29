# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::InfoLevel::Component, type: :component do
  let(:component) { Bali::InfoLevel::Component.new(**@options) }

  before { @options = {} }

  context 'with one title' do
    it 'renders' do
      render_inline(component) do |c|
        c.with_item do |ci|
          ci.with_heading('Heading')
          ci.with_title('Title')
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
        c.with_item do |ci|
          ci.with_heading('Heading')
          ci.with_title('Title 1')
          ci.with_title('Title 2')
        end
      end

      expect(page).to have_css '.info-level-component'
      expect(page).to have_css '.heading', text: 'Heading'
      expect(page).to have_css '.title', text: 'Title 1'
      expect(page).to have_css '.title', text: 'Title 2'
    end
  end

  context 'with custom heading' do
    it 'renders' do
      render_inline(component) do |c|
        c.with_item do |ci|
          ci.with_heading do
            'My custom heading'
          end

          ci.with_title('Title')
        end
      end

      expect(page).to have_css '.info-level-component'
      expect(page).to have_css '.heading', text: 'My custom heading'
      expect(page).to have_css '.title', text: 'Title'
    end
  end

  context 'with custom title' do
    it 'renders' do
      render_inline(component) do |c|
        c.with_item do |ci|
          ci.with_heading('Heading')

          ci.with_title do
            'My custom title'
          end
        end
      end

      expect(page).to have_css '.info-level-component'
      expect(page).to have_css '.heading', text: 'Heading'
      expect(page).to have_css '.title', text: 'My custom title'
    end
  end
end
