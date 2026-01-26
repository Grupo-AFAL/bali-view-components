# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#password_field_group' do
    subject(:password_field_group) { builder.password_field_group(:budget) }

    it 'renders a fieldset wrapper' do
      expect(password_field_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a legend label' do
      expect(password_field_group).to have_css 'legend.fieldset-legend', text: 'Budget'
    end

    it 'renders a password input with correct attributes' do
      expect(password_field_group).to have_css(
        'input#movie_budget[type="password"][name="movie[budget]"]'
      )
    end

    it 'applies DaisyUI input classes' do
      expect(password_field_group).to have_css 'input.input.input-bordered'
    end
  end

  describe '#password_field' do
    subject(:password_field) { builder.password_field(:budget) }

    it 'renders a div with control class' do
      expect(password_field).to have_css 'div.control'
    end

    it 'renders a password input with correct attributes' do
      expect(password_field).to have_css(
        'input#movie_budget[type="password"][name="movie[budget]"]'
      )
    end

    it 'applies DaisyUI input classes' do
      expect(password_field).to have_css 'input.input.input-bordered'
    end

    context 'with custom class' do
      subject(:password_field) { builder.password_field(:budget, class: 'custom-input') }

      it 'includes custom class with DaisyUI classes' do
        expect(password_field).to have_css 'input.input.input-bordered.custom-input'
      end
    end

    context 'with validation errors' do
      before do
        resource.errors.add(:budget, 'is required')
      end

      it 'applies error class to input' do
        expect(password_field).to have_css 'input.input.input-error'
      end

      it 'displays error message' do
        expect(password_field).to have_css 'p.text-error', text: 'Budget is required'
      end
    end

    context 'with help text' do
      subject(:password_field) { builder.password_field(:budget, help: 'Minimum 8 characters') }

      it 'displays help text' do
        expect(password_field).to have_css 'p.label-text-alt', text: 'Minimum 8 characters'
      end
    end

    context 'with data attributes' do
      subject(:password_field) do
        builder.password_field(:budget, data: { testid: 'password-input' })
      end

      it 'passes through data attributes' do
        expect(password_field).to have_css 'input.input[data-testid="password-input"]'
      end
    end

    context 'with addon_left' do
      subject(:password_field) do
        builder.password_field(:budget,
                               addon_left: builder.content_tag(:span, 'Lock', class: 'btn'))
      end

      it 'renders within a join container' do
        expect(password_field).to have_css 'div.join'
      end

      it 'applies join-item class to input' do
        expect(password_field).to have_css 'input.input.join-item'
      end

      it 'renders the addon' do
        expect(password_field).to have_css 'span.btn', text: 'Lock'
      end
    end

    context 'with addon_right' do
      subject(:password_field) do
        builder.password_field(:budget,
                               addon_right: builder.content_tag(:button, 'Show', class: 'btn'))
      end

      it 'renders within a join container' do
        expect(password_field).to have_css 'div.join'
      end

      it 'applies join-item class to input' do
        expect(password_field).to have_css 'input.input.join-item'
      end

      it 'renders the addon' do
        expect(password_field).to have_css 'button.btn', text: 'Show'
      end
    end

    context 'with placeholder' do
      subject(:password_field) { builder.password_field(:budget, placeholder: 'Enter password') }

      it 'renders input with placeholder' do
        expect(password_field).to have_css 'input[placeholder="Enter password"]'
      end
    end

    context 'with required attribute' do
      subject(:password_field) { builder.password_field(:budget, required: true) }

      it 'renders required input' do
        expect(password_field).to have_css 'input[required]'
      end
    end

    context 'with disabled attribute' do
      subject(:password_field) { builder.password_field(:budget, disabled: true) }

      it 'renders disabled input' do
        expect(password_field).to have_css 'input[disabled]'
      end
    end
  end
end
