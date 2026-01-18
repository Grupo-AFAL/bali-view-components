# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#number_field_group' do
    subject(:number_field_group) { builder.number_field_group(:budget) }

    it 'renders a fieldset wrapper' do
      expect(number_field_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a legend label' do
      expect(number_field_group).to have_css 'legend.fieldset-legend', text: 'Budget'
    end

    it 'renders a number input with correct attributes' do
      expect(number_field_group).to have_css(
        'input#movie_budget[type="number"][name="movie[budget]"]'
      )
    end

    it 'applies DaisyUI input classes' do
      expect(number_field_group).to have_css 'input.input.input-bordered'
    end
  end

  describe '#number_field' do
    subject(:number_field) { builder.number_field(:budget) }

    it 'renders a div with control class' do
      expect(number_field).to have_css 'div.control'
    end

    it 'renders a number input with correct attributes' do
      expect(number_field).to have_css(
        'input#movie_budget[type="number"][name="movie[budget]"]'
      )
    end

    it 'applies DaisyUI input classes' do
      expect(number_field).to have_css 'input.input.input-bordered'
    end

    context 'with custom class' do
      subject(:number_field) { builder.number_field(:budget, class: 'custom-input') }

      it 'includes custom class with DaisyUI classes' do
        expect(number_field).to have_css 'input.input.input-bordered.custom-input'
      end
    end

    context 'with validation errors' do
      before do
        resource.errors.add(:budget, 'must be positive')
      end

      it 'applies error class to input' do
        expect(number_field).to have_css 'input.input.input-error'
      end

      it 'displays error message' do
        expect(number_field).to have_css 'p.text-error', text: 'Budget must be positive'
      end
    end

    context 'with help text' do
      subject(:number_field) { builder.number_field(:budget, help: 'Enter amount in dollars') }

      it 'displays help text' do
        expect(number_field).to have_css 'p.label-text-alt', text: 'Enter amount in dollars'
      end
    end

    context 'with data attributes' do
      subject(:number_field) { builder.number_field(:budget, data: { testid: 'budget-input' }) }

      it 'passes through data attributes' do
        expect(number_field).to have_css 'input.input[data-testid="budget-input"]'
      end
    end

    context 'with addon_left' do
      subject(:number_field) do
        builder.number_field(:budget, addon_left: builder.content_tag(:span, '$', class: 'btn'))
      end

      it 'renders within a join container' do
        expect(number_field).to have_css 'div.join'
      end

      it 'applies join-item class to input' do
        expect(number_field).to have_css 'input.input.join-item'
      end

      it 'renders the addon' do
        expect(number_field).to have_css 'span.btn', text: '$'
      end
    end

    context 'with addon_right' do
      subject(:number_field) do
        builder.number_field(:budget, addon_right: builder.content_tag(:span, 'USD', class: 'btn'))
      end

      it 'renders within a join container' do
        expect(number_field).to have_css 'div.join'
      end

      it 'applies join-item class to input' do
        expect(number_field).to have_css 'input.input.join-item'
      end

      it 'renders the addon' do
        expect(number_field).to have_css 'span.btn', text: 'USD'
      end
    end

    context 'with min and max' do
      subject(:number_field) { builder.number_field(:budget, min: 0, max: 1_000_000) }

      it 'renders input with min and max attributes' do
        expect(number_field).to have_css 'input[min="0"][max="1000000"]'
      end
    end

    context 'with step' do
      subject(:number_field) { builder.number_field(:budget, step: 0.01) }

      it 'renders input with step attribute' do
        expect(number_field).to have_css 'input[step="0.01"]'
      end
    end

    context 'with placeholder' do
      subject(:number_field) { builder.number_field(:budget, placeholder: '0.00') }

      it 'renders input with placeholder' do
        expect(number_field).to have_css 'input[placeholder="0.00"]'
      end
    end

    context 'with required attribute' do
      subject(:number_field) { builder.number_field(:budget, required: true) }

      it 'renders required input' do
        expect(number_field).to have_css 'input[required]'
      end
    end

    context 'with disabled attribute' do
      subject(:number_field) { builder.number_field(:budget, disabled: true) }

      it 'renders disabled input' do
        expect(number_field).to have_css 'input[disabled]'
      end
    end
  end
end
