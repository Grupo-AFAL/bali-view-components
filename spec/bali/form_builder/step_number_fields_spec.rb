# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#step_number_field_group' do
    let(:step_number_group) { builder.step_number_field_group(:duration) }

    it 'renders the input and label within a wrapper' do
      expect(step_number_group).to have_css '#field-duration.form-control'
    end

    it 'renders the label' do
      expect(step_number_group).to have_css '.label[for="movie_duration"]', text: 'Duration'
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

    it 'renders the field with the subtract button' do
      expect(step_number_field).to have_css '.btn[data-action="step-number-input#subtract"]'
      expect(step_number_field).to have_css '.btn[data-step-number-input-target="subtract"]'
    end

    it 'renders the input' do
      expect(step_number_field).to have_css 'input[data-step-number-input-target="input"]'
      expect(step_number_field).to have_css '#movie_duration[name="movie[duration]"]'
    end

    it 'renders the field with the add button' do
      expect(step_number_field).to have_css '.btn[data-action="step-number-input#add"]'
      expect(step_number_field).to have_css '.btn[data-step-number-input-target="add"]'
    end
  end
end
