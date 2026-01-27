# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Filters::AppliedTags::Component, type: :component do
  let(:available_attributes) do
    [
      { key: :name, label: 'Name', type: :text },
      { key: :status, label: 'Status', type: :select,
        options: [%w[Active active], %w[Inactive inactive]] },
      { key: :verified, label: 'Verified', type: :boolean }
    ]
  end

  describe 'with no active filters' do
    it 'renders nothing when filter_groups is empty' do
      render_inline(described_class.new(
                      filter_groups: [],
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      expect(page).not_to have_css('.applied-filters')
    end

    it 'renders nothing when conditions have no values' do
      filter_groups = [
        {
          combinator: 'or',
          conditions: [{ attribute: 'name', operator: 'cont', value: '' }]
        }
      ]

      render_inline(described_class.new(
                      filter_groups: filter_groups,
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      expect(page).not_to have_css('.applied-filters')
    end
  end

  describe 'with active filters' do
    let(:filter_groups) do
      [
        {
          combinator: 'or',
          conditions: [
            { attribute: 'name', operator: 'cont', value: 'John' },
            { attribute: 'status', operator: 'eq', value: 'active' }
          ]
        }
      ]
    end

    it 'renders the applied filters container' do
      render_inline(described_class.new(
                      filter_groups: filter_groups,
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      expect(page).to have_css('.applied-filters')
      expect(page).to have_css('[data-controller="applied-tags"]')
    end

    it 'renders filter tags as badges' do
      render_inline(described_class.new(
                      filter_groups: filter_groups,
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      expect(page).to have_css('.badge', count: 2)
    end

    it 'displays attribute label in tag' do
      render_inline(described_class.new(
                      filter_groups: filter_groups,
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      expect(page).to have_text('Name')
      expect(page).to have_text('Status')
    end

    it 'displays operator label in tag' do
      render_inline(described_class.new(
                      filter_groups: filter_groups,
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      expect(page).to have_text('contains')
      expect(page).to have_text('is')
    end

    it 'displays value in tag' do
      render_inline(described_class.new(
                      filter_groups: filter_groups,
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      expect(page).to have_text('John')
      expect(page).to have_text('Active') # Displays label, not value
    end

    it 'renders remove button for each tag' do
      render_inline(described_class.new(
                      filter_groups: filter_groups,
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      expect(page).to have_css('button[data-action="applied-tags#removeFilter"]', count: 2)
    end

    it 'renders clear all link when multiple filters' do
      render_inline(described_class.new(
                      filter_groups: filter_groups,
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      expect(page).to have_link('Clear all')
    end

    it 'does not render clear all link with single filter' do
      single_filter = [
        {
          combinator: 'or',
          conditions: [{ attribute: 'name', operator: 'cont', value: 'John' }]
        }
      ]

      render_inline(described_class.new(
                      filter_groups: single_filter,
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      expect(page).not_to have_link('Clear all')
    end
  end

  describe 'value labels' do
    it 'shows option label for select type' do
      filter_groups = [
        {
          combinator: 'or',
          conditions: [{ attribute: 'status', operator: 'eq', value: 'active' }]
        }
      ]

      render_inline(described_class.new(
                      filter_groups: filter_groups,
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      # Should show 'Active' not 'active'
      expect(page).to have_text('Active')
    end

    it 'shows Yes/No for boolean type' do
      filter_groups = [
        {
          combinator: 'or',
          conditions: [{ attribute: 'verified', operator: 'eq', value: 'true' }]
        }
      ]

      render_inline(described_class.new(
                      filter_groups: filter_groups,
                      available_attributes: available_attributes,
                      url: '/users'
                    ))

      expect(page).to have_text('Yes')
    end
  end

  describe 'any_filters?' do
    it 'returns true when filters have values' do
      filter_groups = [
        {
          combinator: 'or',
          conditions: [{ attribute: 'name', operator: 'cont', value: 'John' }]
        }
      ]

      component = described_class.new(
        filter_groups: filter_groups,
        available_attributes: available_attributes,
        url: '/users'
      )

      expect(component.any_filters?).to be true
    end

    it 'returns false when no filters have values' do
      filter_groups = [
        {
          combinator: 'or',
          conditions: [{ attribute: 'name', operator: 'cont', value: '' }]
        }
      ]

      component = described_class.new(
        filter_groups: filter_groups,
        available_attributes: available_attributes,
        url: '/users'
      )

      expect(component.any_filters?).to be false
    end
  end
end
