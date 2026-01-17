# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Clipboard::Component, type: :component do
  let(:component) { described_class.new(**options) }
  let(:options) { {} }

  describe 'basic rendering' do
    it 'renders clipboard component with DaisyUI join class' do
      render_inline(component) do |c|
        c.with_trigger('Copy')
        c.with_source('Click button to copy me!')
      end

      expect(page).to have_css 'div.clipboard-component.join'
      expect(page).to have_css 'div.clipboard-component[data-controller="clipboard"]'
    end

    it 'renders trigger button with DaisyUI btn classes' do
      render_inline(component) do |c|
        c.with_trigger('Copy')
        c.with_source('Text')
      end

      expect(page).to have_css 'button.btn.btn-ghost.clipboard-trigger', text: 'Copy'
      expect(page).to have_css 'button[data-clipboard-target="button"]'
      expect(page).to have_css 'button[data-action="click->clipboard#copy"]'
      expect(page).to have_css 'button[type="button"]'
    end

    it 'renders source with DaisyUI input classes' do
      render_inline(component) do |c|
        c.with_trigger('Copy')
        c.with_source('Click button to copy me!')
      end

      expect(page).to have_css 'div.clipboard-source.input.input-bordered', text: 'Click button to copy me!'
      expect(page).to have_css 'div[data-clipboard-target="source"]'
    end
  end

  describe 'success content' do
    it 'renders default success content with translation' do
      render_inline(component) do |c|
        c.with_trigger('Copy')
        c.with_source('Text')
      end

      expect(page).to have_css 'span.clipboard-sucess-content.hidden.text-success', text: 'Copied!'
      expect(page).to have_css 'span[data-clipboard-target="successContent"]'
    end

    it 'renders custom success content when provided' do
      render_inline(component) do |c|
        c.with_trigger('Copy')
        c.with_source('Text')
        c.with_success_content('Done!')
      end

      expect(page).to have_css 'span.clipboard-sucess-content', text: 'Done!'
      expect(page).not_to have_text 'Copied!'
    end

    it 'renders success content with block' do
      render_inline(component) do |c|
        c.with_trigger('Copy')
        c.with_source('Text')
        c.with_success_content { 'Custom success' }
      end

      expect(page).to have_css 'span.clipboard-sucess-content', text: 'Custom success'
    end
  end

  describe 'block content' do
    it 'renders trigger with block content' do
      render_inline(component) do |c|
        c.with_trigger { 'Block trigger' }
        c.with_source('Text')
      end

      expect(page).to have_css 'button.clipboard-trigger', text: 'Block trigger'
    end

    it 'renders source with block content' do
      render_inline(component) do |c|
        c.with_trigger('Copy')
        c.with_source { 'Block source' }
      end

      expect(page).to have_css 'div.clipboard-source', text: 'Block source'
    end
  end

  describe 'options passthrough' do
    let(:options) { { class: 'custom-class', data: { testid: 'clipboard' } } }

    it 'accepts custom classes' do
      render_inline(component) do |c|
        c.with_trigger('Copy')
        c.with_source('Text')
      end

      expect(page).to have_css 'div.clipboard-component.custom-class'
    end

    it 'accepts data attributes' do
      render_inline(component) do |c|
        c.with_trigger('Copy')
        c.with_source('Text')
      end

      expect(page).to have_css 'div[data-testid="clipboard"]'
    end

    it 'passes custom classes to trigger' do
      render_inline(component) do |c|
        c.with_trigger('Copy', class: 'my-trigger')
        c.with_source('Text')
      end

      expect(page).to have_css 'button.clipboard-trigger.my-trigger'
    end

    it 'passes custom classes to source' do
      render_inline(component) do |c|
        c.with_trigger('Copy')
        c.with_source('Text', class: 'my-source')
      end

      expect(page).to have_css 'div.clipboard-source.my-source'
    end
  end

  describe 'accessibility' do
    it 'includes default aria-label on trigger' do
      render_inline(component) do |c|
        c.with_trigger('Copy')
        c.with_source('Text')
      end

      expect(page).to have_css 'button[aria-label="Copy to clipboard"]'
    end

    it 'allows custom aria-label on trigger' do
      render_inline(component) do |c|
        c.with_trigger('Copy', 'aria-label': 'Copy API key')
        c.with_source('abc123')
      end

      expect(page).to have_css 'button[aria-label="Copy API key"]'
    end
  end

  describe 'BASE_CLASSES constants' do
    it 'defines BASE_CLASSES on main component' do
      expect(described_class::BASE_CLASSES).to eq 'clipboard-component join'
    end

    it 'defines BASE_CLASSES on Source component' do
      expect(Bali::Clipboard::Source::Component::BASE_CLASSES).to include 'clipboard-source'
      expect(Bali::Clipboard::Source::Component::BASE_CLASSES).to include 'input'
    end

    it 'defines BASE_CLASSES on Trigger component' do
      expect(Bali::Clipboard::Trigger::Component::BASE_CLASSES).to include 'btn'
      expect(Bali::Clipboard::Trigger::Component::BASE_CLASSES).to include 'clipboard-trigger'
    end

    it 'defines BASE_CLASSES on SucessContent component' do
      expect(Bali::Clipboard::SucessContent::Component::BASE_CLASSES).to include 'hidden'
      expect(Bali::Clipboard::SucessContent::Component::BASE_CLASSES).to include 'text-success'
    end
  end
end
