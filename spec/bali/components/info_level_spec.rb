# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::InfoLevel::Component, type: :component do
  let(:component) { described_class.new(**@options) }

  before { @options = {} }

  def render_with_item
    render_inline(component) do |c|
      c.with_item do |ci|
        ci.with_heading('Heading')
        ci.with_title('Title')
      end
    end
  end

  describe 'basic rendering' do
    it 'renders a div container' do
      render_with_item
      expect(page).to have_css 'div.info-level-component'
    end

    it 'renders with base classes' do
      render_with_item
      expect(page).to have_css '.info-level-component.flex.flex-wrap.gap-8'
    end

    it 'renders heading and title' do
      render_with_item
      expect(page).to have_css '.heading', text: 'Heading'
      expect(page).to have_css '.title', text: 'Title'
    end
  end

  describe 'alignment' do
    described_class::ALIGNMENTS.each do |align, css_class|
      it "applies #{align} alignment" do
        @options = { align: align }
        render_with_item
        expect(page).to have_css ".info-level-component.#{css_class}"
      end
    end

    it 'defaults to center alignment' do
      render_with_item
      expect(page).to have_css '.info-level-component.justify-center'
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      @options = { class: 'custom-class' }
      render_with_item
      expect(page).to have_css '.info-level-component.custom-class'
    end

    it 'accepts data attributes' do
      @options = { data: { testid: 'info-level' } }
      render_with_item
      expect(page).to have_css '[data-testid="info-level"]'
    end

    it 'accepts id attribute' do
      @options = { id: 'my-info-level' }
      render_with_item
      expect(page).to have_css '#my-info-level.info-level-component'
    end
  end

  describe 'multiple items' do
    it 'renders multiple items' do
      render_inline(component) do |c|
        c.with_item do |ci|
          ci.with_heading('Heading 1')
          ci.with_title('Title 1')
        end

        c.with_item do |ci|
          ci.with_heading('Heading 2')
          ci.with_title('Title 2')
        end
      end

      expect(page).to have_css '.level-item', count: 2
      expect(page).to have_css '.heading', count: 2
      expect(page).to have_css '.title', count: 2
    end
  end

  describe 'multiple titles per item' do
    it 'renders multiple titles' do
      render_inline(component) do |c|
        c.with_item do |ci|
          ci.with_heading('Heading')
          ci.with_title('Title 1')
          ci.with_title('Title 2')
        end
      end

      expect(page).to have_css '.heading', text: 'Heading'
      expect(page).to have_css '.title', text: 'Title 1'
      expect(page).to have_css '.title', text: 'Title 2'
    end
  end

  describe 'custom heading block' do
    it 'renders custom heading content' do
      render_inline(component) do |c|
        c.with_item do |ci|
          ci.with_heading { 'My custom heading' }
          ci.with_title('Title')
        end
      end

      expect(page).to have_css '.heading', text: 'My custom heading'
    end
  end

  describe 'custom title block' do
    it 'renders custom title content' do
      render_inline(component) do |c|
        c.with_item do |ci|
          ci.with_heading('Heading')
          ci.with_title { 'My custom title' }
        end
      end

      expect(page).to have_css '.title', text: 'My custom title'
    end
  end
end

RSpec.describe Bali::InfoLevel::Item::Component, type: :component do
  describe 'base classes' do
    it 'renders with level-item and text-center classes' do
      render_inline(described_class.new) do |c|
        c.with_heading('H')
        c.with_title('T')
      end

      expect(page).to have_css '.level-item.text-center'
    end
  end

  describe 'heading slot' do
    it 'renders heading with proper classes' do
      render_inline(described_class.new) do |c|
        c.with_heading('My Heading')
        c.with_title('T')
      end

      expect(page).to have_css '.heading.text-xs.uppercase.tracking-wide', text: 'My Heading'
    end

    it 'allows custom classes on heading' do
      render_inline(described_class.new) do |c|
        c.with_heading('H', class: 'extra-class')
        c.with_title('T')
      end

      expect(page).to have_css '.heading.extra-class'
    end
  end

  describe 'title slot' do
    it 'renders title with proper classes' do
      render_inline(described_class.new) do |c|
        c.with_heading('H')
        c.with_title('My Title')
      end

      expect(page).to have_css '.title.text-2xl.font-bold', text: 'My Title'
    end

    it 'allows custom classes on title' do
      render_inline(described_class.new) do |c|
        c.with_heading('H')
        c.with_title('T', class: 'extra-class')
      end

      expect(page).to have_css '.title.extra-class'
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes on item' do
      render_inline(described_class.new(class: 'custom-item')) do |c|
        c.with_heading('H')
        c.with_title('T')
      end

      expect(page).to have_css '.level-item.custom-item'
    end

    it 'accepts data attributes on item' do
      render_inline(described_class.new(data: { testid: 'item' })) do |c|
        c.with_heading('H')
        c.with_title('T')
      end

      expect(page).to have_css '[data-testid="item"]'
    end
  end
end
