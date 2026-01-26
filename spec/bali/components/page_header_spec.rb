# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::PageHeader::Component, type: :component do
  describe 'constants' do
    it 'defines BASE_CLASSES' do
      expect(described_class::BASE_CLASSES).to eq('page-header-component')
    end

    it 'defines frozen HEADING_SIZES' do
      expect(described_class::HEADING_SIZES).to be_frozen
      expect(described_class::HEADING_SIZES[:h1]).to eq('text-4xl')
      expect(described_class::HEADING_SIZES[:h3]).to eq('text-2xl')
    end

    it 'defines frozen ALIGNMENTS' do
      expect(described_class::ALIGNMENTS).to be_frozen
      expect(described_class::ALIGNMENTS).to eq(top: :start, center: :center, bottom: :end)
    end

    it 'defines BACK_BUTTON_CLASSES' do
      expect(described_class::BACK_BUTTON_CLASSES).to include('btn', 'btn-ghost')
    end

    it 'defines TITLE_CLASSES' do
      expect(described_class::TITLE_CLASSES).to include('title', 'font-bold')
    end

    it 'defines SUBTITLE_CLASSES' do
      expect(described_class::SUBTITLE_CLASSES).to include('subtitle', 'text-base-content/60')
    end
  end

  describe 'rendering' do
    context 'with title and subtitle as params' do
      it 'renders' do
        render_inline(described_class.new(title: 'Title', subtitle: 'Subtitle'))

        expect(page).to have_css '.level-left h3.title', text: 'Title'
        expect(page).to have_css '.level-left h5.subtitle', text: 'Subtitle'
      end
    end

    context 'with title and subtitle as slots' do
      context 'when using text param' do
        it 'renders' do
          render_inline(described_class.new) do |c|
            c.with_title('Title')
            c.with_subtitle('Subtitle')
            'Right content'
          end

          expect(page).to have_css '.level-left h3.title', text: 'Title'
          expect(page).to have_css '.level-left h5.subtitle', text: 'Subtitle'
          expect(page).to have_css '.level-right', text: 'Right content'
        end
      end

      context 'when using the tag param' do
        it 'renders with custom heading tags' do
          render_inline(described_class.new) do |c|
            c.with_title('Title', tag: :h2)
            c.with_subtitle('Subtitle', tag: :h4)
          end

          expect(page).to have_css '.level-left h2.title', text: 'Title'
          expect(page).to have_css '.level-left h4.subtitle', text: 'Subtitle'
        end
      end

      context 'with custom classes' do
        it 'renders with DaisyUI text classes' do
          render_inline(described_class.new) do |c|
            c.with_title('Title', class: 'text-info')
            c.with_subtitle('Subtitle', class: 'text-primary')
          end

          expect(page).to have_css '.level-left h3.title.text-info', text: 'Title'
          expect(page).to have_css '.level-left h5.subtitle.text-primary', text: 'Subtitle'
        end
      end

      context 'when using blocks' do
        it 'renders custom content' do
          render_inline(described_class.new) do |c|
            c.with_title { '<h2 class="title">Title</h2>'.html_safe }
            c.with_subtitle { '<p class="subtitle">Subtitle</p>'.html_safe }
            'Right content'
          end

          expect(page).to have_css '.level-left h2.title', text: 'Title'
          expect(page).to have_css '.level-left p.subtitle', text: 'Subtitle'
          expect(page).to have_css '.level-right', text: 'Right content'
        end
      end
    end
  end

  describe 'alignment' do
    it 'passes top alignment to Level as :start' do
      render_inline(described_class.new(title: 'Title', align: :top))

      expect(page).to have_css '.level.items-start'
    end

    it 'passes center alignment to Level as :center' do
      render_inline(described_class.new(title: 'Title', align: :center))

      expect(page).to have_css '.level.items-center'
    end

    it 'passes bottom alignment to Level as :end' do
      render_inline(described_class.new(title: 'Title', align: :bottom))

      expect(page).to have_css '.level.items-end'
    end

    it 'defaults to center alignment' do
      render_inline(described_class.new(title: 'Title'))

      expect(page).to have_css '.level.items-center'
    end
  end

  describe 'back button' do
    it 'renders back button when href is provided' do
      render_inline(described_class.new(title: 'Title', back: { href: '/back' }))

      expect(page).to have_css '.back-button[href="/back"]'
      expect(page).to have_css '.btn.btn-ghost'
    end

    it 'does not render back button when back is nil' do
      render_inline(described_class.new(title: 'Title'))

      expect(page).not_to have_css '.back-button'
    end

    it 'does not render back button when href is blank' do
      render_inline(described_class.new(title: 'Title', back: { href: '' }))

      expect(page).not_to have_css '.back-button'
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes via options' do
      render_inline(described_class.new(title: 'Title', class: 'custom-class'))

      expect(page).to have_css '.page-header-component.custom-class'
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(title: 'Title', data: { testid: 'page-header' }))

      expect(page).to have_css '[data-testid="page-header"]'
    end
  end
end
