# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::AdvancedFilters::Condition::Component, type: :component do
  let(:available_attributes) do
    [
      { key: :name, label: 'Name', type: :text },
      { key: :status, label: 'Status', type: :select,
        options: [%w[Active active], %w[Inactive inactive]] },
      { key: :age, label: 'Age', type: :number },
      { key: :created_at, label: 'Created', type: :date },
      { key: :verified, label: 'Verified', type: :boolean }
    ]
  end

  let(:empty_condition) { { attribute: '', operator: 'cont', value: '' } }

  describe 'rendering' do
    it 'renders the condition container' do
      render_inline(described_class.new(
                      condition: empty_condition,
                      group_index: 0,
                      condition_index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('.condition')
      expect(page).to have_css('[data-controller="condition"]')
    end

    it 'renders attribute selector with all options' do
      render_inline(described_class.new(
                      condition: empty_condition,
                      group_index: 0,
                      condition_index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_select(with_options: %w[Name Status Age Created Verified])
    end

    it 'renders operator selector' do
      render_inline(described_class.new(
                      condition: empty_condition,
                      group_index: 0,
                      condition_index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('select[data-condition-target="operator"]')
    end

    it 'renders value input' do
      render_inline(described_class.new(
                      condition: empty_condition,
                      group_index: 0,
                      condition_index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('[data-condition-target="valueContainer"]')
    end

    it 'renders remove button' do
      render_inline(described_class.new(
                      condition: empty_condition,
                      group_index: 0,
                      condition_index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('button[data-action="condition#remove"]')
    end
  end

  describe 'with pre-selected attribute' do
    it 'selects the attribute in the dropdown' do
      condition = { attribute: 'name', operator: 'cont', value: 'John' }

      render_inline(described_class.new(
                      condition: condition,
                      group_index: 0,
                      condition_index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('option[value="name"][selected]')
    end

    it 'shows text input for text type' do
      condition = { attribute: 'name', operator: 'cont', value: 'John' }

      render_inline(described_class.new(
                      condition: condition,
                      group_index: 0,
                      condition_index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('input[type="text"][data-condition-target="value"]')
    end

    it 'shows number input for number type' do
      condition = { attribute: 'age', operator: 'eq', value: '25' }

      render_inline(described_class.new(
                      condition: condition,
                      group_index: 0,
                      condition_index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('input[type="number"][data-condition-target="value"]')
    end

    it 'shows select for select type' do
      condition = { attribute: 'status', operator: 'eq', value: 'active' }

      render_inline(described_class.new(
                      condition: condition,
                      group_index: 0,
                      condition_index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('select[data-condition-target="value"]')
      expect(page).to have_select(with_options: %w[Active Inactive])
    end

    it 'shows select for boolean type' do
      condition = { attribute: 'verified', operator: 'eq', value: 'true' }

      render_inline(described_class.new(
                      condition: condition,
                      group_index: 0,
                      condition_index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('select[data-condition-target="value"]')
      expect(page).to have_select(with_options: %w[Any Yes No])
    end

    it 'shows date input for date type' do
      condition = { attribute: 'created_at', operator: 'eq', value: '2026-01-01' }

      render_inline(described_class.new(
                      condition: condition,
                      group_index: 0,
                      condition_index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('input[data-controller="datepicker"]')
    end
  end

  describe 'field_name' do
    it 'builds correct Ransack field name' do
      condition = { attribute: 'status', operator: 'eq', value: 'active' }

      component = described_class.new(
        condition: condition,
        group_index: 1,
        condition_index: 0,
        available_attributes: available_attributes
      )

      expect(component.field_name).to eq('q[g][1][status_eq]')
    end

    it 'uses placeholder for empty attribute' do
      component = described_class.new(
        condition: empty_condition,
        group_index: 0,
        condition_index: 0,
        available_attributes: available_attributes
      )

      expect(component.field_name).to eq('q[g][0][__ATTR___cont]')
    end
  end

  describe 'operators_for_current_type' do
    it 'returns operators for the selected attribute type' do
      condition = { attribute: 'age', operator: 'eq', value: '' }

      component = described_class.new(
        condition: condition,
        group_index: 0,
        condition_index: 0,
        available_attributes: available_attributes
      )

      operators = component.operators_for_current_type
      expect(operators.map { |o| o[:value] }).to include('eq', 'gt', 'lt')
    end

    it 'defaults to text operators when no attribute selected' do
      component = described_class.new(
        condition: empty_condition,
        group_index: 0,
        condition_index: 0,
        available_attributes: available_attributes
      )

      operators = component.operators_for_current_type
      expect(operators.map { |o| o[:value] }).to include('cont', 'eq')
    end
  end

  describe 'multiple_operator?' do
    it 'returns true for in operator' do
      condition = { attribute: 'status', operator: 'in', value: [] }

      component = described_class.new(
        condition: condition,
        group_index: 0,
        condition_index: 0,
        available_attributes: available_attributes
      )

      expect(component.multiple_operator?).to be true
    end

    it 'returns true for not_in operator' do
      condition = { attribute: 'status', operator: 'not_in', value: [] }

      component = described_class.new(
        condition: condition,
        group_index: 0,
        condition_index: 0,
        available_attributes: available_attributes
      )

      expect(component.multiple_operator?).to be true
    end

    it 'returns false for eq operator' do
      condition = { attribute: 'status', operator: 'eq', value: 'active' }

      component = described_class.new(
        condition: condition,
        group_index: 0,
        condition_index: 0,
        available_attributes: available_attributes
      )

      expect(component.multiple_operator?).to be false
    end
  end
end
