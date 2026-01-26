# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tooltip::Component, type: :component do
  describe 'constants' do
    it 'has frozen POSITIONS hash' do
      expect(described_class::POSITIONS).to be_frozen
    end

    it 'defines all four positions' do
      expect(described_class::POSITIONS.keys).to contain_exactly(:top, :bottom, :left, :right)
    end

    it 'has CONTROLLER constant' do
      expect(described_class::CONTROLLER).to eq('tooltip')
    end
  end

  describe 'basic rendering' do
    it 'renders tooltip with trigger content' do
      render_inline(described_class.new) do |c|
        c.with_trigger { c.tag.span '?' }
        c.tag.p 'Tooltip content'
      end

      expect(page).to have_css '.tooltip-component'
      expect(page).to have_css '.trigger', text: '?'
    end

    it 'includes stimulus controller data attributes' do
      render_inline(described_class.new) do |c|
        c.with_trigger { c.tag.span 'Hover' }
      end

      expect(page).to have_css '[data-controller="tooltip"]'
      expect(page).to have_css '[data-tooltip-target="trigger"]'
      expect(page).to have_css 'template[data-tooltip-target="content"]', visible: false
    end

    it 'renders inline-block container' do
      render_inline(described_class.new) do |c|
        c.with_trigger { c.tag.span 'Hover' }
      end

      expect(page).to have_css '.inline-block'
    end
  end

  describe 'placement' do
    described_class::POSITIONS.each_key do |placement|
      it "sets #{placement} placement" do
        render_inline(described_class.new(placement: placement)) do |c|
          c.with_trigger { c.tag.span 'Hover' }
        end

        expect(page).to have_css "[data-tooltip-placement-value=\"#{placement}\"]"
      end
    end

    it 'defaults to top placement' do
      render_inline(described_class.new) do |c|
        c.with_trigger { c.tag.span 'Hover' }
      end

      expect(page).to have_css '[data-tooltip-placement-value="top"]'
    end

    it 'handles invalid placement gracefully' do
      render_inline(described_class.new(placement: :invalid)) do |c|
        c.with_trigger { c.tag.span 'Hover' }
      end

      expect(page).to have_css '[data-tooltip-placement-value="top"]'
    end
  end

  describe 'custom trigger events' do
    it 'sets custom trigger event' do
      render_inline(described_class.new(trigger_event: 'click')) do |c|
        c.with_trigger { c.tag.span 'Click me' }
      end

      expect(page).to have_css '[data-tooltip-trigger-value="click"]'
    end

    it 'defaults to mouseenter focus' do
      render_inline(described_class.new) do |c|
        c.with_trigger { c.tag.span 'Hover' }
      end

      expect(page).to have_css '[data-tooltip-trigger-value="mouseenter focus"]'
    end
  end

  describe 'options passthrough' do
    it 'accepts custom class via options' do
      render_inline(described_class.new(class: 'help-tip')) do |c|
        c.with_trigger { c.tag.span '?' }
      end

      expect(page).to have_css '.tooltip-component.help-tip'
    end

    it 'passes through data attributes' do
      render_inline(described_class.new(data: { testid: 'my-tooltip' })) do |c|
        c.with_trigger { c.tag.span 'Hover' }
      end

      expect(page).to have_css '[data-testid="my-tooltip"]'
    end

    it 'merges data attributes with stimulus data' do
      render_inline(described_class.new(data: { custom: 'value' })) do |c|
        c.with_trigger { c.tag.span 'Hover' }
      end

      expect(page).to have_css '[data-controller="tooltip"][data-custom="value"]'
    end

    it 'passes through arbitrary HTML attributes' do
      render_inline(described_class.new(id: 'tooltip-1', role: 'tooltip')) do |c|
        c.with_trigger { c.tag.span 'Hover' }
      end

      expect(page).to have_css '#tooltip-1[role="tooltip"]'
    end
  end

  describe 'trigger slot' do
    it 'renders custom trigger content' do
      render_inline(described_class.new) do |c|
        c.with_trigger { c.tag.button 'Click me', class: 'btn btn-primary' }
        c.tag.p 'Tooltip text'
      end

      expect(page).to have_css '.trigger button.btn.btn-primary', text: 'Click me'
    end
  end
end
