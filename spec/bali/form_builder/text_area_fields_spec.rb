# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#text_area_group' do
    let(:text_area_group) { builder.text_area_group(:synopsis) }

    it 'renders a fieldset wrapper' do
      expect(text_area_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a legend label' do
      expect(text_area_group).to have_css 'legend.fieldset-legend', text: 'Synopsis'
    end

    it 'renders a text area with correct name' do
      expect(text_area_group).to have_css 'textarea#movie_synopsis[name="movie[synopsis]"]'
    end

    it 'applies DaisyUI textarea classes' do
      expect(text_area_group).to have_css 'textarea.textarea.textarea-bordered'
    end
  end

  describe '#text_area' do
    let(:text_area) { builder.text_area(:synopsis) }

    it 'renders a control wrapper' do
      expect(text_area).to have_css 'div.control'
    end

    it 'renders a text area element' do
      expect(text_area).to have_css 'textarea#movie_synopsis[name="movie[synopsis]"]'
    end

    it 'applies DaisyUI textarea classes' do
      expect(text_area).to have_css 'textarea.textarea.textarea-bordered'
    end

    context 'with custom class' do
      let(:text_area) { builder.text_area(:synopsis, class: 'min-h-32') }

      it 'merges custom classes' do
        expect(text_area).to have_css 'textarea.textarea.textarea-bordered.min-h-32'
      end
    end

    context 'with validation errors' do
      before { resource.errors.add(:synopsis, 'is required') }

      it 'applies error class' do
        expect(text_area).to have_css 'textarea.input-error'
      end

      it 'displays error message' do
        expect(text_area).to have_css 'p.text-error', text: 'Synopsis is required'
      end
    end

    context 'with help text' do
      let(:text_area) { builder.text_area(:synopsis, help: 'Enter a brief synopsis') }

      it 'displays help text' do
        expect(text_area).to have_css 'p.label-text-alt', text: 'Enter a brief synopsis'
      end
    end

    context 'with rows option' do
      let(:text_area) { builder.text_area(:synopsis, rows: 5) }

      it 'applies rows attribute' do
        expect(text_area).to have_css 'textarea[rows="5"]'
      end
    end

    context 'with placeholder' do
      let(:text_area) { builder.text_area(:synopsis, placeholder: 'Enter synopsis...') }

      it 'applies placeholder attribute' do
        expect(text_area).to have_css 'textarea[placeholder="Enter synopsis..."]'
      end
    end

    context 'with char_counter: true' do
      let(:text_area) { builder.text_area(:synopsis, char_counter: true) }

      it 'wraps textarea in Stimulus controller div' do
        expect(text_area).to have_css 'div[data-controller="textarea"]'
      end

      it 'adds textarea target to input' do
        expect(text_area).to have_css 'textarea[data-textarea-target="input"]'
      end

      it 'adds input action to textarea' do
        expect(text_area).to have_css 'textarea[data-action="input->textarea#onInput"]'
      end

      it 'renders counter element' do
        expect(text_area).to have_css 'p[data-textarea-target="counter"]'
      end

      it 'sets max-length value to 0 when no max provided' do
        expect(text_area).to have_css 'div[data-textarea-max-length-value="0"]'
      end
    end

    context 'with char_counter: { max: 500 }' do
      let(:text_area) { builder.text_area(:synopsis, char_counter: { max: 500 }) }

      it 'sets max-length value from options' do
        expect(text_area).to have_css 'div[data-textarea-max-length-value="500"]'
      end

      it 'renders counter element with correct class' do
        expect(text_area).to have_css 'p.label-text-alt[data-textarea-target="counter"]'
      end
    end

    context 'with auto_grow: true' do
      let(:text_area) { builder.text_area(:synopsis, auto_grow: true) }

      it 'wraps textarea in Stimulus controller div' do
        expect(text_area).to have_css 'div[data-controller="textarea"]'
      end

      it 'sets auto-grow value to true' do
        expect(text_area).to have_css 'div[data-textarea-auto-grow-value="true"]'
      end

      it 'adds textarea target to input' do
        expect(text_area).to have_css 'textarea[data-textarea-target="input"]'
      end

      it 'does not render counter element' do
        expect(text_area).not_to have_css '[data-textarea-target="counter"]'
      end
    end

    context 'with both char_counter and auto_grow' do
      let(:text_area) { builder.text_area(:synopsis, char_counter: { max: 200 }, auto_grow: true) }

      it 'wraps textarea in Stimulus controller div' do
        expect(text_area).to have_css 'div[data-controller="textarea"]'
      end

      it 'sets both max-length and auto-grow values' do
        expect(text_area).to have_css 'div[data-textarea-max-length-value="200"][data-textarea-auto-grow-value="true"]'
      end

      it 'renders counter element' do
        expect(text_area).to have_css 'p[data-textarea-target="counter"]'
      end
    end
  end
end
