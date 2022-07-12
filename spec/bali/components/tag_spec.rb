# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tag::Component, type: :component do
  before { @options = {} }
  let(:component) { Bali::Tag::Component.new(**@options) }

  describe 'rendering tag with' do
    before { @options.merge!(text: 'Tag item with text') }

    it 'single item text' do
      render_inline(component)

      expect(page).to have_css 'div.tag-component.tag', text: 'Tag item with text'
    end

    before { @options.merge!(text: 'Tag item with text', color: :black) }

    it 'single item color' do
      render_inline(component)

      expect(page).to have_css 'div.is-black.tag-component.tag', text: 'Tag item with text'
    end

    before { @options.merge!(text: 'Tag item with text', size: :small) }

    it 'single item size' do
      render_inline(component)

      expect(page).to have_css 'div.tag-component.tag.is-small', text: 'Tag item with text'
    end

    before { @options.merge!(text: 'Tag item with text', light: true) }

    it 'single item light' do
      render_inline(component)

      expect(page).to have_css 'div.tag-component.tag.is-light', text: 'Tag item with text'
    end

    before { @options.merge!(text: 'Tag item with text', rounded: true) }

    it 'single item rounded' do
      render_inline(component)

      expect(page).to have_css 'div.tag-component.tag.is-rounded', text: 'Tag item with text'
    end
  end
end
