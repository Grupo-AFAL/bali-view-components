# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Pagination::Component, type: :component do
  let(:pagy) { Pagy.new(count: 100, page: 3, items: 10) }

  it 'renders pagination with multiple pages' do
    render_inline(described_class.new(pagy: pagy))

    expect(page).to have_css 'nav.pagy-nav-daisyui'
    expect(page).to have_css '.join'
    expect(page).to have_css '.join-item.btn', minimum: 5
  end

  it 'renders previous and next buttons' do
    render_inline(described_class.new(pagy: pagy))

    expect(page).to have_css 'a.join-item', text: '«'
    expect(page).to have_css 'a.join-item', text: '»'
  end

  it 'marks current page as active' do
    render_inline(described_class.new(pagy: pagy))

    expect(page).to have_css 'button.btn-active', text: '3'
  end

  it 'does not render when only one page' do
    single_page = Pagy.new(count: 5, page: 1, items: 10)
    render_inline(described_class.new(pagy: single_page))

    expect(page).not_to have_css 'nav'
  end

  it 'disables previous button on first page' do
    first_page = Pagy.new(count: 100, page: 1, items: 10)
    render_inline(described_class.new(pagy: first_page))

    expect(page).to have_css 'button.btn-disabled[disabled]', text: '«'
  end

  it 'disables next button on last page' do
    last_page = Pagy.new(count: 100, page: 10, items: 10)
    render_inline(described_class.new(pagy: last_page))

    expect(page).to have_css 'button.btn-disabled[disabled]', text: '»'
  end

  it 'applies size classes' do
    render_inline(described_class.new(pagy: pagy, size: :sm))

    expect(page).to have_css '.btn-sm'
  end

  it 'applies variant classes' do
    render_inline(described_class.new(pagy: pagy, variant: :outline))

    expect(page).to have_css '.btn-outline'
  end
end
