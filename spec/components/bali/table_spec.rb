# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::PageHeader::Component, type: :component do
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

    expect(rendered_component).to have_css 'table'
    expect(rendered_component).to have_css 'tr th', text: 'name'
    expect(rendered_component).to have_css 'tr th', text: 'amount'
  end

  it 'renders a table with rows' do
    render_inline(component) do |c|
      c.row { '<td>Hola</td>'.html_safe }
    end

    expect(rendered_component).to have_css 'tr td', text: 'Hola'
  end

  it 'renders a table with footer' do
    render_inline(component) do |c|
      c.footer { '<td>Total</td>'.html_safe }
    end

    expect(rendered_component).to have_css 'table'
    expect(rendered_component).to have_css 'tfoot tr td', text: 'Total'
  end

  it 'renders an empty table without results' do
    render_inline(component)

    expect(rendered_component).to have_css '.empty-table p', text: 'No Records'
  end

  it 'renders an empty query message' do
    @options.merge!(form: @filter_form)
    render_inline(component)

    expect(rendered_component).to have_css '.empty-table p',
                                           text: 'No Records'
  end
end
