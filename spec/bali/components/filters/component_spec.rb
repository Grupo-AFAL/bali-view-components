# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Filters::Component, type: :component do
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

      expect(page).to have_css('.filters')
      expect(page).to have_css('[data-controller="filters"]')
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
      expect(page).to have_css('[data-filters-target="addGroupButton"]')
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

  describe 'persistence toggle' do
    it 'returns false for persistence_available? when no storage_id' do
      component = described_class.new(
        url: '/users',
        available_attributes: available_attributes
      )

      expect(component.persistence_available?).to be false
    end

    it 'returns true for persistence_available? when storage_id is present' do
      component = described_class.new(
        url: '/users',
        available_attributes: available_attributes,
        storage_id: 'users_filters'
      )

      expect(component.persistence_available?).to be true
    end

    it 'returns false for persist_enabled? by default' do
      component = described_class.new(
        url: '/users',
        available_attributes: available_attributes,
        storage_id: 'users_filters'
      )

      expect(component.persist_enabled?).to be false
    end

    it 'returns true for persist_enabled? when explicitly enabled' do
      component = described_class.new(
        url: '/users',
        available_attributes: available_attributes,
        storage_id: 'users_filters',
        persist_enabled: true
      )

      expect(component.persist_enabled?).to be true
    end

    it 'does not render persistence toggle when storage_id is absent' do
      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes
                    ))

      expect(page).not_to have_css('[data-controller="filter-persistence"]')
    end

    it 'renders persistence toggle when storage_id is present' do
      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes,
                      storage_id: 'users_filters'
                    ))

      expect(page).to have_css('[data-controller="filter-persistence"]')
    end

    it 'shows disabled icon by default' do
      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes,
                      storage_id: 'users_filters'
                    ))

      expect(page).to have_css('[data-filter-persistence-target="iconDisabled"]:not(.hidden)')
      expect(page).to have_css('[data-filter-persistence-target="iconEnabled"].hidden')
    end

    it 'shows enabled icon when persist_enabled is true' do
      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes,
                      storage_id: 'users_filters',
                      persist_enabled: true
                    ))

      expect(page).to have_css('[data-filter-persistence-target="iconEnabled"]:not(.hidden)')
      expect(page).to have_css('[data-filter-persistence-target="iconDisabled"].hidden')
    end

    it 'renders auto-saved text in footer only when persistence is enabled' do
      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes,
                      storage_id: 'users_filters',
                      persist_enabled: true
                    ))

      expect(page).to have_text('Auto-saved')
    end

    it 'does not render auto-saved text when persistence is disabled' do
      render_inline(described_class.new(
                      url: '/users',
                      available_attributes: available_attributes,
                      storage_id: 'users_filters',
                      persist_enabled: false
                    ))

      expect(page).not_to have_text('Auto-saved')
    end
  end

  describe '#preserved_query_params' do
    it 'extracts non-filter params from URL' do
      component = described_class.new(
        url: '/users?page=2&per=25&q[name_cont]=test',
        available_attributes: available_attributes
      )

      expect(component.preserved_query_params).to contain_exactly(
        %w[page 2],
        %w[per 25]
      )
    end

    it 'handles nested params' do
      component = described_class.new(
        url: '/users?sort[column]=name&sort[direction]=asc',
        available_attributes: available_attributes
      )

      expect(component.preserved_query_params).to contain_exactly(
        ['sort[column]', 'name'],
        ['sort[direction]', 'asc']
      )
    end

    it 'handles array params' do
      component = described_class.new(
        url: '/users?ids[]=1&ids[]=2&ids[]=3',
        available_attributes: available_attributes
      )

      expect(component.preserved_query_params).to contain_exactly(
        ['ids[]', '1'],
        ['ids[]', '2'],
        ['ids[]', '3']
      )
    end

    it 'returns empty array when URL has no query params' do
      component = described_class.new(
        url: '/users',
        available_attributes: available_attributes
      )

      expect(component.preserved_query_params).to eq([])
    end

    it 'excludes q params' do
      component = described_class.new(
        url: '/users?page=2&q[name_cont]=test&q[status_eq]=active',
        available_attributes: available_attributes
      )

      expect(component.preserved_query_params).to contain_exactly(%w[page 2])
    end

    it 'excludes clear_filters and clear_search params' do
      component = described_class.new(
        url: '/users?page=2&clear_filters=true&clear_search=true',
        available_attributes: available_attributes
      )

      expect(component.preserved_query_params).to contain_exactly(%w[page 2])
    end
  end

  describe '#preserved_params_hidden_fields' do
    it 'renders hidden fields for preserved params' do
      render_inline(described_class.new(
                      url: '/users?page=2&per=25',
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('input[type="hidden"][name="page"][value="2"]', visible: :hidden)
      expect(page).to have_css('input[type="hidden"][name="per"][value="25"]', visible: :hidden)
    end

    it 'does not render hidden fields for filter params' do
      render_inline(described_class.new(
                      url: '/users?page=2&q[name_cont]=test',
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('input[type="hidden"][name="page"][value="2"]', visible: :hidden)
      expect(page).not_to have_css('input[type="hidden"][name="q[name_cont]"]', visible: :hidden)
    end
  end
end
