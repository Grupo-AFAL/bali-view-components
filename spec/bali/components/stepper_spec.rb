# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Stepper::Component, type: :component do
  describe 'rendering' do
    it 'renders stepper with DaisyUI steps classes' do
      render_inline(described_class.new(current: 0)) do |c|
        c.with_step(title: 'Step One')
        c.with_step(title: 'Step Two')
      end

      expect(page).to have_css('ul.steps')
      expect(page).to have_css('li.step', count: 2)
    end

    it 'renders horizontal orientation by default' do
      render_inline(described_class.new(current: 0)) do |c|
        c.with_step(title: 'Step One')
      end

      expect(page).to have_css('ul.steps.steps-horizontal')
    end

    it 'renders vertical orientation when specified' do
      render_inline(described_class.new(current: 0, orientation: :vertical)) do |c|
        c.with_step(title: 'Step One')
      end

      expect(page).to have_css('ul.steps.steps-vertical')
    end
  end

  describe 'step states' do
    it 'renders first step as active with color class' do
      render_inline(described_class.new(current: 0)) do |c|
        c.with_step(title: 'Step One')
        c.with_step(title: 'Step Two')
        c.with_step(title: 'Step Three')
      end

      # First step is active - gets color class
      expect(page).to have_css('li.step.step-primary', text: 'Step One')
      # Other steps are pending - no color class
      expect(page).to have_css('li.step:not(.step-primary)', text: 'Step Two')
      expect(page).to have_css('li.step:not(.step-primary)', text: 'Step Three')
    end

    it 'renders completed steps with color class and checkmark' do
      render_inline(described_class.new(current: 1)) do |c|
        c.with_step(title: 'Step One')
        c.with_step(title: 'Step Two')
        c.with_step(title: 'Step Three')
      end

      # First step is done - gets color class and checkmark
      expect(page).to have_css('li.step.step-primary[data-content="✓"]', text: 'Step One')
      # Second step is active - gets color class, no checkmark
      expect(page).to have_css('li.step.step-primary', text: 'Step Two')
      # Third step is pending - no color class
      expect(page).to have_css('li.step:not(.step-primary)', text: 'Step Three')
    end

    it 'renders all steps as done except last one active' do
      render_inline(described_class.new(current: 2)) do |c|
        c.with_step(title: 'Step One')
        c.with_step(title: 'Step Two')
        c.with_step(title: 'Step Three')
      end

      expect(page).to have_css('li.step.step-primary[data-content="✓"]', text: 'Step One')
      expect(page).to have_css('li.step.step-primary[data-content="✓"]', text: 'Step Two')
      expect(page).to have_css('li.step.step-primary', text: 'Step Three')
    end
  end

  describe 'color variants' do
    Bali::Stepper::Step::Component::COLORS.each_key do |color|
      it "applies #{color} color to completed steps" do
        render_inline(described_class.new(current: 1, color: color)) do |c|
          c.with_step(title: 'Step One')
          c.with_step(title: 'Step Two')
        end

        expect(page).to have_css("li.step.step-#{color}")
      end
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes on stepper' do
      render_inline(described_class.new(current: 0, class: 'custom-class')) do |c|
        c.with_step(title: 'Step One')
      end

      expect(page).to have_css('ul.steps.custom-class')
    end

    it 'accepts custom classes on steps' do
      render_inline(described_class.new(current: 0)) do |c|
        c.with_step(title: 'Step One', class: 'my-step')
      end

      expect(page).to have_css('li.step.my-step')
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(current: 0, data: { testid: 'stepper' })) do |c|
        c.with_step(title: 'Step One')
      end

      expect(page).to have_css('ul.steps[data-testid="stepper"]')
    end
  end
end

RSpec.describe Bali::Stepper::Step::Component, type: :component do
  describe 'status calculation' do
    it 'returns :active when index equals current' do
      component = described_class.new(title: 'Test', current: 1, index: 1)
      expect(component.status).to eq(:active)
      expect(component.active?).to be true
    end

    it 'returns :done when index is less than current' do
      component = described_class.new(title: 'Test', current: 2, index: 0)
      expect(component.status).to eq(:done)
      expect(component.done?).to be true
    end

    it 'returns :pending when index is greater than current' do
      component = described_class.new(title: 'Test', current: 0, index: 2)
      expect(component.status).to eq(:pending)
      expect(component.pending?).to be true
    end
  end
end
