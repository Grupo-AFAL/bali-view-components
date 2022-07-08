# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tags::Component, type: :component do
  let(:component) { Bali::Tags::Component.new }

  describe 'rendering' do
    context 'tags with' do
      it 'single item text' do
        render_inline(component) do |c|
          c.tag_item(text: 'Tag item with text')
        end

        expect(page).to have_css 'div.tag-component.tag', text: 'Tag item with text'
      end

      it 'single item color' do
        render_inline(component) do |c|
          c.tag_item(text: 'Tag item with text', color: :black)
        end

        expect(page).to have_css 'div.is-black.tag-component.tag', text: 'Tag item with text'
      end

      it 'single item size' do
        render_inline(component) do |c|
          c.tag_item(text: 'Tag item with text', size: :small)
        end

        expect(page).to have_css 'div.tag-component.tag.is-small', text: 'Tag item with text'
      end

      it 'single item light' do
        render_inline(component) do |c|
          c.tag_item(text: 'Tag item with text', light: true)
        end

        expect(page).to have_css 'div.tag-component.tag.is-light', text: 'Tag item with text'
      end

      it 'single item rounded' do
        render_inline(component) do |c|
          c.tag_item(text: 'Tag item with text', rounded: true)
        end

        expect(page).to have_css 'div.tag-component.tag.is-rounded', text: 'Tag item with text'
      end
    end
  end
end
