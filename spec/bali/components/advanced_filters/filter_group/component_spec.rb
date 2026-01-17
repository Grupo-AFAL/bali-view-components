# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::AdvancedFilters::FilterGroup::Component, type: :component do
  let(:available_attributes) do
    [
      { key: :name, label: 'Name', type: :text },
      { key: :status, label: 'Status', type: :select,
        options: [%w[Active active], %w[Inactive inactive]] }
    ]
  end

  let(:default_group) do
    {
      combinator: 'or',
      conditions: [{ attribute: '', operator: 'cont', value: '' }]
    }
  end

  describe 'rendering' do
    it 'renders the filter group container' do
      render_inline(described_class.new(
                      group: default_group,
                      index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('.filter-group')
      expect(page).to have_css('[data-controller="filter-group"]')
    end

    it 'renders the combinator hidden input' do
      render_inline(described_class.new(
                      group: default_group,
                      index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('input[type="hidden"][name="q[g][0][m]"]', visible: :hidden)
    end

    it 'renders conditions' do
      render_inline(described_class.new(
                      group: default_group,
                      index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('.condition')
      expect(page).to have_css('[data-controller="condition"]')
    end

    it 'renders add condition button' do
      render_inline(described_class.new(
                      group: default_group,
                      index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_button('Add condition')
    end
  end

  describe 'with multiple conditions' do
    let(:group_with_conditions) do
      {
        combinator: 'and',
        conditions: [
          { attribute: 'name', operator: 'cont', value: 'John' },
          { attribute: 'status', operator: 'eq', value: 'active' }
        ]
      }
    end

    it 'renders all conditions' do
      render_inline(described_class.new(
                      group: group_with_conditions,
                      index: 0,
                      available_attributes: available_attributes
                    ))

      expect(page).to have_css('.condition', count: 2)
    end

    it 'renders combinator toggle for subsequent conditions' do
      render_inline(described_class.new(
                      group: group_with_conditions,
                      index: 0,
                      available_attributes: available_attributes
                    ))

      # First row shows "Where", subsequent rows show AND/OR toggle
      expect(page).to have_text('Where')
      expect(page).to have_button('AND')
      expect(page).to have_button('OR')
    end

    it 'highlights the active combinator' do
      render_inline(described_class.new(
                      group: group_with_conditions,
                      index: 0,
                      available_attributes: available_attributes
                    ))

      # AND should be highlighted (btn-primary) since combinator is 'and'
      expect(page).to have_css('button.btn-primary', text: 'AND')
      expect(page).to have_css('button.btn-outline', text: 'OR')
    end
  end

  describe 'combinator' do
    it 'defaults to or' do
      component = described_class.new(
        group: { conditions: [{ attribute: '', operator: 'cont', value: '' }] },
        index: 0,
        available_attributes: available_attributes
      )

      expect(component.combinator).to eq('or')
    end

    it 'uses the group combinator value' do
      component = described_class.new(
        group: { combinator: 'and', conditions: [] },
        index: 0,
        available_attributes: available_attributes
      )

      expect(component.combinator).to eq('and')
    end
  end

  describe 'group_field_prefix' do
    it 'builds the correct Ransack field prefix' do
      component = described_class.new(
        group: default_group,
        index: 2,
        available_attributes: available_attributes
      )

      expect(component.group_field_prefix).to eq('q[g][2]')
    end
  end
end
