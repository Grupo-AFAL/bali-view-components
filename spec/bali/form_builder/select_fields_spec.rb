# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#select_group' do
    let(:select_group) { builder.select_group(:status, Movie.statuses.to_a) }

    it 'renders a label and input within a wrapper' do
      expect(select_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a label' do
      expect(select_group).to have_css 'legend.fieldset-legend', text: 'Status'
    end

    it 'renders a select with DaisyUI classes' do
      expect(select_group).to have_css 'select.select.select-bordered.w-full#movie_status'
    end

    it 'renders all options' do
      Movie.statuses.each do |name, value|
        expect(select_group).to have_css "option[value=\"#{value}\"]", text: name
      end
    end
  end

  describe '#select_field' do
    let(:select_field) { builder.select_field(:status, Movie.statuses.to_a) }

    it 'renders a div with control class' do
      expect(select_field).to have_css 'div.control'
    end

    it 'renders a select with DaisyUI classes' do
      expect(select_field).to have_css 'select.select.select-bordered.w-full#movie_status'
    end

    it 'renders all options' do
      Movie.statuses.each do |name, value|
        expect(select_field).to have_css "option[value=\"#{value}\"]", text: name
      end
    end

    context 'with custom class' do
      let(:select_field) do
        builder.select_field(:status, Movie.statuses.to_a, {}, class: 'custom-class')
      end

      it 'includes custom class with DaisyUI classes' do
        expect(select_field).to have_css 'select.select.select-bordered.w-full.custom-class'
      end
    end

    context 'with validation errors' do
      before { resource.errors.add(:status, :invalid) }

      it 'renders select with error class' do
        expect(select_field).to have_css 'select.select.select-bordered.w-full.input-error'
      end

      it 'displays error message' do
        expect(select_field).to have_css 'p.text-error'
      end
    end

    context 'with help text' do
      let(:select_field) do
        builder.select_field(:status, Movie.statuses.to_a, {}, help: 'Select a status')
      end

      it 'displays help text' do
        expect(select_field).to have_css 'p.label-text-alt', text: 'Select a status'
      end
    end
  end

  describe 'BASE_CLASSES constant' do
    it 'is frozen' do
      expect(Bali::FormBuilder::SelectFields::BASE_CLASSES).to be_frozen
    end

    it 'contains DaisyUI select classes' do
      expect(Bali::FormBuilder::SelectFields::BASE_CLASSES).to eq 'select select-bordered w-full'
    end
  end
end
