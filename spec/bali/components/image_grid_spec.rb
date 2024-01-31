# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::ImageGrid::Component, type: :component do
  let(:component) { Bali::ImageGrid::Component.new }

  it 'renders the image grid' do
    render_inline(component)

    expect(page).to have_css '.image-grid-component.columns.is-multiline'
  end

  it 'renders 4 images' do
    render_inline(component) do |c|
      4.times do
        c.with_image { c.tag.img src: 'img.png' }
      end
    end

    expect(page).to have_css 'figure.image.is-3by2', count: 4
  end

  it 'renders with customized column size' do
    render_inline(component) do |c|
      4.times do
        c.with_image(column_size: 'is-one-fifth') { c.tag.img src: 'img.png' }
      end
    end

    expect(page).to have_css '.column.is-one-fifth', count: 4
  end
end
