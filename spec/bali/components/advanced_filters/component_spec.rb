# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::AdvancedFilters::Component, type: :component do
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

  describe 'rendering' do
    it 'renders the component' do
      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('.advanced-filters')
      expect(page).to have_css('[data-controller="advanced-filters"]')
    end

    it 'renders a filter group by default' do
      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('.filter-group')
      expect(page).to have_css('[data-controller="filter-group"]')
    end

    it 'renders available attributes in the dropdown' do
      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes
                    ))

      expect(page).to have_select(with_options: %w[Name Status Age Created Verified])
    end

    it 'renders apply and reset buttons' do
      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes
                    ))

      expect(page).to have_button('Apply')
      expect(page).to have_button('Reset')
    end

    it 'renders add group button' do
      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes
                    ))

      # Icon-only button with tooltip in popover mode
      expect(page).to have_css('[data-advanced-filters-target="addGroupButton"]')
    end
  end

  describe 'with initial filter groups' do
    it 'renders pre-populated conditions' do
      filter_groups = [
        {
          combinator: 'or',
          conditions: [
            { attribute: 'status', operator: 'eq', value: 'active' }
          ]
        }
      ]

      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes,
                      filter_groups: filter_groups
                    ))

      expect(page).to have_css('.filter-group')
      # Check that the condition is rendered with Status option available
      expect(page).to have_css('option[value="status"]', text: 'Status')
    end

    it 'renders multiple groups with combinator' do
      filter_groups = [
        { combinator: 'or',
          conditions: [{ attribute: 'status', operator: 'eq', value: 'active' }] },
        { combinator: 'and', conditions: [{ attribute: 'name', operator: 'cont', value: 'test' }] }
      ]

      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes,
                      filter_groups: filter_groups,
                      combinator: :and
                    ))

      expect(page).to have_css('.filter-group', count: 2)
      # Check that the combinator hidden input and toggle buttons exist
      expect(page).to have_css('input[type="hidden"][name="q[m]"]', visible: :hidden)
      expect(page).to have_button('AND')
      expect(page).to have_button('OR')
    end
  end

  describe 'operators' do
    it 'provides correct operators for text type' do
      component = described_class.new(
        url: '/users',
        available_attributes: [{ key: :name, type: :text }]
      )

      operators = component.operators_for_type(:text)

      expect(operators.map { |o| o[:value] }).to include('cont', 'eq', 'start', 'end')
    end

    it 'provides correct operators for number type' do
      component = described_class.new(
        url: '/users',
        available_attributes: [{ key: :age, type: :number }]
      )

      operators = component.operators_for_type(:number)

      expect(operators.map { |o| o[:value] }).to include('eq', 'gt', 'lt', 'gteq', 'lteq')
    end

    it 'provides correct operators for date type' do
      component = described_class.new(
        url: '/users',
        available_attributes: [{ key: :created_at, type: :date }]
      )

      operators = component.operators_for_type(:date)

      expect(operators.map { |o| o[:value] }).to include('eq', 'gt', 'lt', 'gteq', 'lteq')
    end

    it 'provides correct operators for select type' do
      component = described_class.new(
        url: '/users',
        available_attributes: [{ key: :status, type: :select }]
      )

      operators = component.operators_for_type(:select)

      expect(operators.map { |o| o[:value] }).to include('eq', 'not_eq')
    end

    it 'provides correct operators for boolean type' do
      component = described_class.new(
        url: '/users',
        available_attributes: [{ key: :verified, type: :boolean }]
      )

      operators = component.operators_for_type(:boolean)

      expect(operators.map { |o| o[:value] }).to eq(['eq'])
    end
  end
end
