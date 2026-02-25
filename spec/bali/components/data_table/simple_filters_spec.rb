# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::DataTable::SimpleFilters::Component, type: :component do
  let(:filters) do
    [
      {
        attribute: :status,
        collection: [ %w[Active active], %w[Inactive inactive] ],
        blank: 'All',
        label: 'Status',
        value: nil
      }
    ]
  end

  it 'renders filter selects' do
    render_inline(described_class.new(url: '/test', filters: filters))

    expect(page).to have_css("select[name='q[status_eq]']")
    expect(page).to have_css('option', text: 'All')
    expect(page).to have_css('option', text: 'Active')
    expect(page).to have_css('option', text: 'Inactive')
  end

  it 'renders submit button' do
    render_inline(described_class.new(url: '/test', filters: filters))

    expect(page).to have_css('button[type="submit"]')
  end

  it 'renders labels' do
    render_inline(described_class.new(url: '/test', filters: filters))

    expect(page).to have_css('.label-text', text: 'Status')
  end

  it 'shows clear button when show_clear is true' do
    render_inline(described_class.new(url: '/test', filters: filters, show_clear: true))

    expect(page).to have_link(href: '/test')
  end

  it 'hides clear button when show_clear is false' do
    render_inline(described_class.new(url: '/test', filters: filters, show_clear: false))

    expect(page).not_to have_link(text: /Clear/i)
  end

  it 'does not render when filters are empty' do
    render_inline(described_class.new(url: '/test', filters: []))

    expect(page).not_to have_css('form')
  end

  it 'selects the current value' do
    filters_with_value = [
      {
        attribute: :status,
        collection: [ %w[Active active], %w[Inactive inactive] ],
        blank: 'All',
        label: 'Status',
        value: 'active'
      }
    ]

    render_inline(described_class.new(url: '/test', filters: filters_with_value))

    expect(page).to have_css('option[selected]', text: 'Active')
  end

  it 'selects the default value when no current value' do
    filters_with_default = [
      {
        attribute: :status,
        collection: [ %w[Active active], %w[Inactive inactive] ],
        blank: 'All',
        label: 'Status',
        value: nil,
        default: 'inactive'
      }
    ]

    render_inline(described_class.new(url: '/test', filters: filters_with_default))

    expect(page).to have_css('option[selected]', text: 'Inactive')
  end

  it 'renders multiple filters' do
    multi_filters = [
      {
        attribute: :status,
        collection: [ %w[Active active] ],
        blank: 'All Statuses',
        label: 'Status',
        value: nil
      },
      {
        attribute: :category,
        collection: [ %w[Electronics electronics] ],
        blank: 'All Categories',
        label: 'Category',
        value: nil
      }
    ]

    render_inline(described_class.new(url: '/test', filters: multi_filters))

    expect(page).to have_css("select[name='q[status_eq]']")
    expect(page).to have_css("select[name='q[category_eq]']")
    expect(page).to have_css('.label-text', text: 'Status')
    expect(page).to have_css('.label-text', text: 'Category')
  end

  it 'uses turbo frame _top for form submission' do
    render_inline(described_class.new(url: '/test', filters: filters))

    expect(page).to have_css('form[data-turbo-frame="_top"]')
  end

  describe 'search parameter' do
    let(:search) do
      {
        field_name: 'q[name_cont]',
        value: nil,
        placeholder: 'Search by name...'
      }
    end

    it 'renders search input when search is provided' do
      render_inline(described_class.new(url: '/test', filters: filters, search: search))

      expect(page).to have_css("input[type='text'][name='q[name_cont]']")
      expect(page).to have_css("input[placeholder='Search by name...']")
    end

    it 'does not render search input when search is nil' do
      render_inline(described_class.new(url: '/test', filters: filters))

      expect(page).not_to have_css("input[type='text']")
    end

    it 'renders search input before filter selects' do
      render_inline(described_class.new(url: '/test', filters: filters, search: search))

      # Search input and filter select should both be present in the form
      expect(page).to have_css("input[type='text'][name='q[name_cont]']")
      expect(page).to have_css("select[name='q[status_eq]']")
    end

    it 'preserves search value after submission' do
      search_with_value = search.merge(value: 'SAP')
      render_inline(described_class.new(url: '/test', filters: filters, search: search_with_value))

      expect(page).to have_css("input[value='SAP']")
    end

    it 'renders search label' do
      render_inline(described_class.new(url: '/test', filters: filters, search: search))

      expect(page).to have_css('.label-text', text: 'Search')
    end

    it 'renders custom search label' do
      search_with_label = search.merge(label: 'Find records')
      render_inline(described_class.new(url: '/test', filters: filters, search: search_with_label))

      expect(page).to have_css('.label-text', text: 'Find records')
    end

    it 'shows clear button when show_clear is true with search' do
      search_with_value = search.merge(value: 'test')
      render_inline(described_class.new(url: '/test', filters: filters, search: search_with_value, show_clear: true))

      expect(page).to have_link(href: '/test')
    end

    it 'does not show clear button when show_clear is false even with search value' do
      search_with_value = search.merge(value: 'test')
      render_inline(described_class.new(url: '/test', filters: filters, search: search_with_value))

      expect(page).not_to have_link(text: /Clear/i)
    end

    it 'renders with search only and no filters' do
      render_inline(described_class.new(url: '/test', filters: [], search: search))

      expect(page).to have_css('form')
      expect(page).to have_css("input[type='text'][name='q[name_cont]']")
      expect(page).not_to have_css('select')
    end

    it 'submits search and filters together in one form' do
      render_inline(described_class.new(url: '/test', filters: filters, search: search))

      # Both inputs are inside the same form
      expect(page).to have_css('form') do |form|
        expect(form).to have_css("input[name='q[name_cont]']")
        expect(form).to have_css("select[name='q[status_eq]']")
      end
    end
  end
end
