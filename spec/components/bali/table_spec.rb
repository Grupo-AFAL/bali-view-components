# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Table::Component, type: :component do
  let(:component) { Bali::Table::Component.new(**@options) }

  before { @options = {} }

  subject { rendered_component }

  it 'renders a table with headers' do
    render_inline(component) do |c|
      c.headers([
                  { name: 'name' },
                  { name: 'amount' }
                ])
    end

    is_expected.to have_css 'table'
    is_expected.to have_css 'tr th', text: 'name'
    is_expected.to have_css 'tr th', text: 'amount'
  end

  it 'renders a table with rows' do
    render_inline(component) do |c|
      c.row { '<td>Hola</td>'.html_safe }
    end

    is_expected.to have_css 'tr td', text: 'Hola'
  end

  it 'renders a table with footer' do
    render_inline(component) do |c|
      c.footer { '<td>Total</td>'.html_safe }
    end

    is_expected.to have_css 'table'
    is_expected.to have_css 'tfoot tr td', text: 'Total'
  end

  it 'renders an empty table without results' do
    form = double('form')
    allow(form).to receive(:active_filters?) { true }
    allow(form).to receive(:id) { '1' }

    @options = { form: form }
    render_inline(component)

    is_expected.to have_css '.empty-table p', text: 'No Results'
  end

  it 'renders an empty query message' do
    @options.merge!(form: @filter_form)
    render_inline(component)

    is_expected.to have_css '.empty-table p', text: 'No Records'
  end

  xit 'renders a table with new record link' do
    render_inline(component) do |c|
      c.new_record_link(name: 'Add New Record', href: '#', modal: false)
    end

    is_expected.to have_css 'a', text: 'Add New Record'
  end
end
