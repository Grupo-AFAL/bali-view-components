# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Table::Component, type: :component do
  let(:component) { Bali::Table::Component.new(**@options) }

  before { @options = {} }

  it 'renders a table with headers using array syntax' do
    render_inline(component) do |c|
      c.with_headers([
                       { name: 'name' },
                       { name: 'amount' }
                     ])
    end

    expect(page).to have_css 'table'
    expect(page).to have_css 'tr th', text: 'name'
    expect(page).to have_css 'tr th', text: 'amount'
  end

  it 'renders a table with headers using singular syntax' do
    render_inline(component) do |c|
      c.with_header(name: 'name')
      c.with_header(name: 'amount', class: 'text-right')
    end

    expect(page).to have_css 'table'
    expect(page).to have_css 'tr th', text: 'name'
    expect(page).to have_css 'tr th.text-right', text: 'amount'
  end

  it 'renders a table with rows' do
    render_inline(component) do |c|
      c.with_row { '<td>Hola</td>'.html_safe }
    end

    expect(page).to have_css 'tr td', text: 'Hola'
  end

  it 'renders a table with footer' do
    render_inline(component) do |c|
      c.with_footer { '<td>Total</td>'.html_safe }
    end

    expect(page).to have_css 'table'
    expect(page).to have_css 'tfoot tr td', text: 'Total'
  end

  it 'renders an empty table without results' do
    form = double('form')
    allow(form).to receive(:active_filters?) { true }
    allow(form).to receive(:id) { '1' }

    @options = { form: form }
    render_inline(component)

    expect(page).to have_css '.empty-table p', text: 'No Results'
  end

  it 'renders an empty query message' do
    @options.merge!(form: @filter_form)
    render_inline(component)

    expect(page).to have_css '.empty-table p', text: 'No Records'
  end

  it 'renders a table with new record link' do
    render_inline(component) do |c|
      c.with_new_record_link(name: 'Add New Record', href: '#', modal: false)
    end

    expect(page).to have_css 'a', text: 'Add New Record'
  end

  context 'with custom no records notification' do
    it 'renders an empty query message' do
      @options.merge!(form: @filter_form)
      render_inline(component) do |c|
        c.with_no_records_notification { 'So sorry, no records found!' }
      end

      expect(page).to have_css '.empty-table', text: 'So sorry, no records found!'
    end
  end

  context 'with custom no results notification' do
    it 'renders an empty table without results' do
      form = double('form')
      allow(form).to receive(:active_filters?) { true }
      allow(form).to receive(:id) { '1' }

      @options = { form: form }
      render_inline(component) do |c|
        c.with_no_results_notification { 'So sorry, no results!' }
      end

      expect(page).to have_css '.empty-table', text: 'So sorry, no results!'
    end
  end
end
