# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Reveal::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Reveal::Component.new(**options) }

  describe 'rendering' do
    it 'renders with hidden content' do
      render_inline(component)

      expect(page).to have_css 'div.reveal-component'
      expect(page).not_to have_css 'div.reveal-component.is-revealed'
    end

    it 'renders with opened content' do
      options[:opened] = true
      render_inline(component)

      expect(page).to have_css 'div.reveal-component'
      expect(page).to have_css 'div.reveal-component.is-revealed'
    end

    it 'renders reveal content container' do
      render_inline(component) { 'Hidden content' }

      expect(page).to have_css 'div.reveal-content.hidden', text: 'Hidden content'
    end

    it 'includes reveal Stimulus controller' do
      render_inline(component)

      expect(page).to have_css 'div[data-controller~="reveal"]'
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(class: 'custom-class'))

      expect(page).to have_css 'div.reveal-component.custom-class'
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(data: { testid: 'reveal-test' }))

      expect(page).to have_css 'div[data-testid="reveal-test"]'
    end

    it 'accepts id attribute' do
      render_inline(described_class.new(id: 'my-reveal'))

      expect(page).to have_css 'div#my-reveal.reveal-component'
    end
  end

  describe 'trigger' do
    it 'renders trigger with title' do
      render_inline(component) do |c|
        c.with_trigger do |trigger|
          trigger.with_title do
            '<div class="reveal-title">Click here</div>'.html_safe
          end
        end
      end

      expect(page).to have_css 'div.reveal-trigger[data-action="click->reveal#toggle"]'
      expect(page).to have_css 'div.reveal-title', text: 'Click here'
      expect(page).to have_css '.icon-component'
    end

    it 'renders border at bottom by default' do
      render_inline(component) do |c|
        c.with_trigger do |trigger|
          trigger.with_title { 'Click here' }
        end
      end

      expect(page).to have_css 'div.reveal-trigger.border-b'
    end

    it 'hides border when show_border is false' do
      render_inline(component) do |c|
        c.with_trigger(show_border: false) do |trigger|
          trigger.with_title { 'Click here' }
        end
      end

      expect(page).not_to have_css 'div.reveal-trigger.border-b'
    end

    it 'accepts custom icon class' do
      render_inline(component) do |c|
        c.with_trigger(icon_class: 'text-primary') do |trigger|
          trigger.with_title { 'Click here' }
        end
      end

      expect(page).to have_css '.trigger-icon.text-primary'
    end

    it 'rotates icon when revealed' do
      render_inline(component) do |c|
        c.with_trigger do |trigger|
          trigger.with_title { 'Click here' }
        end
      end

      # Icon starts rotated and unrotates when parent has is-revealed
      expect(page).to have_css '.trigger-icon.rotate-\\[270deg\\]'
    end
  end

  describe 'constants' do
    it 'has frozen BASE_CLASSES' do
      expect(described_class::BASE_CLASSES).to be_frozen
    end

    it 'has frozen OPENED_CLASS' do
      expect(described_class::OPENED_CLASS).to be_frozen
    end
  end
end
