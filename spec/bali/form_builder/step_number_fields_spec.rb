# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#step_number_field_group' do
    let(:step_number_group) { builder.step_number_field_group(:duration) }

    it 'renders the input and label within a wrapper' do
      expect(step_number_group).to have_css '#field-duration.fieldset'
    end

    it 'renders the label' do
      expect(step_number_group).to have_css 'legend.fieldset-legend', text: 'Duration'
    end

    it 'renders the input' do
      expect(step_number_group).to have_css 'input#movie_duration[name="movie[duration]"]'
    end
  end

  describe '#step_number_field' do
    let(:step_number_field) { builder.step_number_field(:duration) }

    it 'renders the field with the step-number-input controller' do
      expect(step_number_field).to have_css '.join[data-controller="step-number-input"]'
    end

    describe 'subtract button' do
      it 'renders with correct Stimulus action' do
        expect(step_number_field).to have_css 'button[data-action*="step-number-input#subtract"]'
      end

      it 'renders with correct Stimulus target' do
        expect(step_number_field).to have_css 'button[data-step-number-input-target="subtract"]'
      end

      it 'renders with aria-label for accessibility' do
        expect(step_number_field).to have_css 'button[aria-label="Decrease value"]'
      end

      it 'renders with DaisyUI button classes' do
        expect(step_number_field).to have_css 'button.btn.join-item'
      end

      it 'renders with minus icon' do
        expect(step_number_field).to have_css 'button span.icon-component svg.lucide-icon'
      end
    end

    describe 'input field' do
      it 'renders with correct target attribute' do
        expect(step_number_field).to have_css 'input[data-step-number-input-target="input"]'
      end

      it 'renders with DaisyUI input classes' do
        expect(step_number_field).to have_css 'input.input.input-bordered.join-item'
      end

      it 'renders with correct name and id' do
        expect(step_number_field).to have_css '#movie_duration[name="movie[duration]"]'
      end

      it 'applies text-center class for alignment' do
        expect(step_number_field).to have_css 'input.text-center'
      end
    end

    describe 'add button' do
      it 'renders with correct Stimulus action' do
        expect(step_number_field).to have_css 'button[data-action*="step-number-input#add"]'
      end

      it 'renders with correct Stimulus target' do
        expect(step_number_field).to have_css 'button[data-step-number-input-target="add"]'
      end

      it 'renders with aria-label for accessibility' do
        expect(step_number_field).to have_css 'button[aria-label="Increase value"]'
      end

      it 'renders with plus icon' do
        expect(step_number_field).to have_css 'button span.icon-component svg.lucide-icon'
      end
    end

    context 'when disabled' do
      let(:step_number_field) { builder.step_number_field(:duration, disabled: true) }

      it 'renders disabled buttons with btn-disabled class' do
        expect(step_number_field).to have_css 'button.btn-disabled.pointer-events-none[disabled]',
                                              count: 2
      end

      it 'does not add data actions to disabled buttons' do
        expect(step_number_field).not_to have_css 'button[disabled][data-action]'
      end

      it 'renders disabled input' do
        expect(step_number_field).to have_css 'input[disabled]'
      end
    end

    context 'with custom button class' do
      let(:step_number_field) { builder.step_number_field(:duration, button_class: 'btn-primary') }

      it 'applies the custom class to both buttons' do
        expect(step_number_field).to have_css 'button.btn.btn-primary', count: 2
      end
    end

    context 'with custom data attributes' do
      let(:step_number_field) do
        builder.step_number_field(:duration,
                                  subtract_data: { turbo_frame: '_top' },
                                  add_data: { confirm: 'Sure?' })
      end

      it 'merges subtract data attributes' do
        expect(step_number_field).to have_css 'button[data-turbo-frame="_top"]'
      end

      it 'merges add data attributes' do
        expect(step_number_field).to have_css 'button[data-confirm="Sure?"]'
      end

      it 'preserves Stimulus actions when merging' do
        expect(step_number_field).to have_css 'button[data-turbo-frame="_top"][data-action*="step-number-input#subtract"]'
      end
    end

    context 'when called multiple times in the same form' do
      it 'renders each field independently without memoization issues' do
        first_field = builder.step_number_field(:duration, button_class: 'btn-primary')
        second_field = builder.step_number_field(:duration, button_class: 'btn-secondary')

        expect(first_field).to have_css 'button.btn-primary', count: 2
        expect(second_field).to have_css 'button.btn-secondary', count: 2
        expect(second_field).not_to have_css 'button.btn-primary'
      end

      it 'does not carry over subtract_data between calls' do
        first_field = builder.step_number_field(:duration, subtract_data: { custom: 'first' })
        second_field = builder.step_number_field(:duration)

        expect(first_field).to have_css 'button[data-custom="first"]'
        expect(second_field).not_to have_css 'button[data-custom]'
      end
    end

    context 'with min, max, and step attributes' do
      let(:step_number_field) { builder.step_number_field(:duration, min: 0, max: 100, step: 5) }

      it 'passes min attribute to the input' do
        expect(step_number_field).to have_css 'input[min="0"]'
      end

      it 'passes max attribute to the input' do
        expect(step_number_field).to have_css 'input[max="100"]'
      end

      it 'passes step attribute to the input' do
        expect(step_number_field).to have_css 'input[step="5"]'
      end
    end

    context 'with custom input class' do
      let(:step_number_field) { builder.step_number_field(:duration, class: 'w-20') }

      it 'appends custom class to default input classes' do
        expect(step_number_field).to have_css 'input.input.input-bordered.join-item.w-20'
      end
    end

    context 'with value' do
      let(:step_number_field) { builder.step_number_field(:duration, value: 42) }

      it 'sets the value on the input' do
        expect(step_number_field).to have_css 'input[value="42"]'
      end
    end
  end

  describe 'constants' do
    it 'defines frozen BUTTON_BASE_CLASSES constant' do
      expect(described_class::StepNumberFields::BUTTON_BASE_CLASSES).to be_frozen
      expect(described_class::StepNumberFields::BUTTON_BASE_CLASSES).to eq 'btn join-item'
    end

    it 'defines frozen BUTTON_DISABLED_CLASSES constant' do
      expect(described_class::StepNumberFields::BUTTON_DISABLED_CLASSES).to be_frozen
      expect(described_class::StepNumberFields::BUTTON_DISABLED_CLASSES).to eq 'btn-disabled pointer-events-none'
    end

    it 'defines frozen INPUT_CLASSES constant' do
      expect(described_class::StepNumberFields::INPUT_CLASSES).to be_frozen
      expect(described_class::StepNumberFields::INPUT_CLASSES).to include('input input-bordered join-item text-center')
      expect(described_class::StepNumberFields::INPUT_CLASSES).to include('[appearance:textfield]')
    end
  end
end
