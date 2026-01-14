# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Carousel::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Carousel::Component.new(**options) }

  it 'renders component' do
    render_inline(component) do |c|
      c.with_item do
        '<img src="https://placehold.co/320x244" />'.html_safe
      end
    end

    expect(page).to have_css '.glide .glide__track .glide__slides'
  end

  it 'render component with second item selected' do
    options.merge!(start_at: 1)
    render_inline(component) do |c|
      c.with_item do
        '<img src="https://placehold.co/320x244" />'.html_safe
      end
    end

    expect(page).to have_css 'div[data-carousel-start-at-value="1"]'
  end
end
