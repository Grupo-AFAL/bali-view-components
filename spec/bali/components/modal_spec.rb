# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Modal::Component, type: :component do
  describe 'basic rendering' do
    it 'renders with modal-open when active is true' do
      render_inline(described_class.new(active: true))

      expect(page).to have_css 'div.modal.modal-open'
    end

    it 'renders without modal-open when active is false' do
      render_inline(described_class.new(active: false))

      expect(page).to have_css 'div.modal'
      expect(page).not_to have_css 'div.modal-open'
    end

    it 'renders with modal-box' do
      render_inline(described_class.new)

      expect(page).to have_css 'div.modal-box'
    end

    it 'renders close button' do
      render_inline(described_class.new)

      expect(page).to have_css 'button[aria-label="Close modal"]'
    end
  end

  describe 'content' do
    it 'renders custom content' do
      render_inline(described_class.new) do
        '<p>Hello World!</p>'.html_safe
      end

      expect(page).to have_css 'p', text: 'Hello World!'
    end
  end

  describe 'sizes' do
    %i[sm md lg xl full].each do |size|
      it "renders #{size} size" do
        render_inline(described_class.new(size: size))

        expect(page).to have_css "div.modal-box.max-w-#{size}"
      end
    end
  end

  describe 'custom classes' do
    it 'merges custom classes' do
      render_inline(described_class.new(class: 'custom-class'))

      expect(page).to have_css 'div.modal-component.custom-class'
    end
  end
end
