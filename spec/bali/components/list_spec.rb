# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::List::Component, type: :component do
  let(:component) { Bali::List::Component.new }

  it 'renders list item with text arguments' do
    render_inline(component) do |c|
      c.item do |i|
        i.title 'Item 1'
        i.subtitle 'Subtitle 1'
      end
    end

    expect(page).to have_css '.title.is-6', text: 'Item 1'
    expect(page).to have_css '.subtitle.is-7', text: 'Subtitle 1'
  end

  it 'renders list item with block arguments' do
    render_inline(component) do |c|
      c.item do |i|
        i.title { 'Item 1' }
        i.subtitle { 'Subtitle 1' }
      end
    end

    expect(page).to have_css '.title.is-6', text: 'Item 1'
    expect(page).to have_css '.subtitle.is-7', text: 'Subtitle 1'
  end

  it 'renders list item actions' do
    render_inline(component) do |c|
      c.item do |i|
        i.action do
          c.tag.a('Link 1', href: '/link-1')
        end
      end
    end

    expect(page).to have_css 'a[href="/link-1"]', text: 'Link 1'
  end
end
