# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tooltip::Component, type: :component do
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
  end

  describe 'placement' do
    %i[top bottom left right].each do |placement|
      it "sets #{placement} placement" do
        render_inline(described_class.new(placement: placement)) do |c|
          c.with_trigger { c.tag.span 'Hover' }
        end

        expect(page).to have_css "[data-tooltip-placement-value=\"#{placement}\"]"
      end
    end
  end

  describe 'custom trigger events' do
    it 'sets custom trigger event' do
      render_inline(described_class.new(trigger: 'click')) do |c|
        c.with_trigger { c.tag.span 'Click me' }
      end

      expect(page).to have_css '[data-tooltip-trigger-value="click"]'
    end
  end
end
