# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#text_field_group' do
    subject(:text_field_group) { builder.text_field_group(:name) }

    it 'renders a fieldset wrapper' do
      expect(text_field_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a legend label' do
      expect(text_field_group).to have_css 'legend.fieldset-legend', text: 'Name'
    end

    it 'renders a text input with correct attributes' do
      expect(text_field_group).to have_css(
        'input#movie_name[type="text"][name="movie[name]"]'
      )
    end

    it 'applies DaisyUI input classes' do
      expect(text_field_group).to have_css 'input.input.input-bordered'
    end
  end

  describe '#text_field' do
    subject(:text_field) { builder.text_field(:name) }

    it 'renders a div with control class' do
      expect(text_field).to have_css 'div.control'
    end

    it 'renders a text input with correct attributes' do
      expect(text_field).to have_css(
        'input#movie_name[type="text"][name="movie[name]"]'
      )
    end

    it 'applies DaisyUI input classes' do
      expect(text_field).to have_css 'input.input.input-bordered'
    end

    context 'with custom class' do
      subject(:text_field) { builder.text_field(:name, class: 'custom-input') }

      it 'includes custom class with DaisyUI classes' do
        expect(text_field).to have_css 'input.input.input-bordered.custom-input'
      end
    end

    context 'with validation errors' do
      before do
        resource.errors.add(:name, 'is invalid')
      end

      it 'applies error class to input' do
        expect(text_field).to have_css 'input.input.input-error'
      end

      it 'displays error message' do
        expect(text_field).to have_css 'p.text-error', text: 'Name is invalid'
      end
    end

    context 'with help text' do
      subject(:text_field) { builder.text_field(:name, help: 'Enter your name') }

      it 'displays help text' do
        expect(text_field).to have_css 'p.label-text-alt', text: 'Enter your name'
      end
    end

    context 'with data attributes' do
      subject(:text_field) { builder.text_field(:name, data: { testid: 'name-input' }) }

      it 'passes through data attributes' do
        expect(text_field).to have_css 'input.input[data-testid="name-input"]'
      end
    end

    context 'with addon_left' do
      subject(:text_field) do
        builder.text_field(:name,
                           addon_left: builder.content_tag(:span, '@', class: 'btn'))
      end

      it 'renders within a join container' do
        expect(text_field).to have_css 'div.join'
      end

      it 'applies join-item class to input' do
        expect(text_field).to have_css 'input.input.join-item'
      end

      it 'renders the addon' do
        expect(text_field).to have_css 'span.btn', text: '@'
      end
    end

    context 'with addon_right' do
      subject(:text_field) do
        builder.text_field(:name,
                           addon_right: builder.content_tag(:span, '.com', class: 'btn'))
      end

      it 'renders within a join container' do
        expect(text_field).to have_css 'div.join'
      end

      it 'applies join-item class to input' do
        expect(text_field).to have_css 'input.input.join-item'
      end

      it 'renders the addon' do
        expect(text_field).to have_css 'span.btn', text: '.com'
      end
    end

    context 'with placeholder' do
      subject(:text_field) { builder.text_field(:name, placeholder: 'Enter your name') }

      it 'renders input with placeholder' do
        expect(text_field).to have_css 'input[placeholder="Enter your name"]'
      end
    end

    context 'with required attribute' do
      subject(:text_field) { builder.text_field(:name, required: true) }

      it 'renders required input' do
        expect(text_field).to have_css 'input[required]'
      end
    end

    context 'with disabled attribute' do
      subject(:text_field) { builder.text_field(:name, disabled: true) }

      it 'renders disabled input' do
        expect(text_field).to have_css 'input[disabled]'
      end
    end
  end
end
