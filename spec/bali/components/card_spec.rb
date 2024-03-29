# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Card::Component, type: :component do
  let(:component) { Bali::Card::Component.new }

  it 'renders a card with content' do
    render_inline(component) do
      '<div class="content">Content</div>'.html_safe
    end

    expect(page).to have_css '.content', text: 'Content'
  end

  it 'renders a card with an clickable image' do
    render_inline(component) do |c|
      c.with_image(src: '/image.png', href: '/path/to/page')
    end

    expect(page).to have_css 'a[href="/path/to/page"] img[src="/image.png"]'
  end

  it 'renders a card with footer item link' do
    render_inline(component) do |c|
      c.with_footer_item(href: '/path') { 'Link to path' }
    end

    expect(page).to have_css 'a[href="/path"].card-footer-item', text: 'Link to path'
  end

  it 'renders a card with regular footer item' do
    render_inline(component) do |c|
      c.with_footer_item do
        '<span class="hola">Hola</span>'.html_safe
      end
    end

    expect(page).to have_css '.card-footer-item span.hola', text: 'Hola'
  end

  it 'renders a card with custom image' do
    render_inline(component) do |c|
      c.with_image do
        '<div class="image-content">Custom content in image</div>'.html_safe
      end

      c.with_footer_item(href: '/path') { 'Link to path' }

      '<div class="content">Content</div>'.html_safe
    end

    expect(page).to have_css '.image-content', text: 'Custom content in image'
  end
end
