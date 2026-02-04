# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::PaginationFooter::Component, type: :component do
  let(:pagy) { Pagy.new(count: 47, page: 1, items: 10) }

  it 'renders summary text' do
    render_inline(described_class.new(pagy: pagy))

    expect(page).to have_text('Showing 1-10 of 47 items')
  end

  it 'renders pagination when multiple pages' do
    render_inline(described_class.new(pagy: pagy))

    expect(page).to have_css('.join') # Pagination component uses join class
  end

  it 'hides pagination when single page' do
    single_page_pagy = Pagy.new(count: 5, page: 1, items: 10)
    render_inline(described_class.new(pagy: single_page_pagy))

    expect(page).not_to have_css('.join')
  end

  it 'uses custom item name' do
    render_inline(described_class.new(pagy: pagy, item_name: 'studios'))

    expect(page).to have_text('Showing 1-10 of 47 studios')
  end

  it 'hides summary when show_summary is false' do
    render_inline(described_class.new(pagy: pagy, show_summary: false))

    expect(page).not_to have_text('Showing')
  end

  it 'hides pagination when show_pagination is false' do
    render_inline(described_class.new(pagy: pagy, show_pagination: false))

    expect(page).not_to have_css('.join')
  end

  it 'does not render when pagy is nil' do
    render_inline(described_class.new(pagy: nil))

    expect(page.text).to be_blank
  end

  it 'renders flex container with justify-between' do
    render_inline(described_class.new(pagy: pagy))

    expect(page).to have_css('.flex.items-center.justify-between')
  end

  it 'shows correct page range on page 2' do
    page_2_pagy = Pagy.new(count: 47, page: 2, items: 10)
    render_inline(described_class.new(pagy: page_2_pagy))

    expect(page).to have_text('Showing 11-20 of 47 items')
  end

  it 'shows correct range on last page' do
    last_page_pagy = Pagy.new(count: 47, page: 5, items: 10)
    render_inline(described_class.new(pagy: last_page_pagy))

    expect(page).to have_text('Showing 41-47 of 47 items')
  end
end
