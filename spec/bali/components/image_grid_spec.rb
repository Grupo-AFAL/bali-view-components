# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::ImageGrid::Component, type: :component do
  let(:component) { Bali::ImageGrid::Component.new }

  it 'renders the image grid' do
    render_inline(component)

    expect(page).to have_css '.image-grid-component.grid.grid-cols-4'
  end

  it 'renders 4 images' do
    render_inline(component) do |c|
      4.times do
        c.with_image { c.tag.img src: 'img.png' }
      end
    end

    expect(page).to have_css 'figure.image', count: 4
  end

  it 'renders with image-grid-item class' do
    render_inline(component) do |c|
      4.times do
        c.with_image { c.tag.img src: 'img.png' }
      end
    end

    expect(page).to have_css '.image-grid-item', count: 4
  end
end
