# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Icon::Component, type: :component do
  describe 'basic rendering' do
    it 'renders with icon-component class' do
      # Using a legacy icon that will always exist
      render_inline(described_class.new('snowflake'))

      expect(page).to have_css 'span.icon-component'
    end

    it 'renders with custom id and classes' do
      render_inline(described_class.new('snowflake', id: 'my-icon', class: 'text-info'))

      expect(page).to have_css 'span.icon-component.text-info'
      expect(page).to have_css 'span[id="my-icon"]'
    end
  end

  describe 'sizes' do
    it 'renders with small size class' do
      render_inline(described_class.new('snowflake', size: :small))

      expect(page).to have_css 'span.icon-component.size-4'
    end

    it 'renders with medium size class' do
      render_inline(described_class.new('snowflake', size: :medium))

      expect(page).to have_css 'span.icon-component.size-8'
    end

    it 'renders with large size class' do
      render_inline(described_class.new('snowflake', size: :large))

      expect(page).to have_css 'span.icon-component.size-12'
    end
  end

  describe 'resolution pipeline' do
    context 'with Lucide-mapped icons' do
      it 'renders mapped icons through Lucide' do
        # 'user' is mapped to Lucide's 'user' icon
        render_inline(described_class.new('user'))

        expect(page).to have_css 'span.icon-component'
        expect(page).to have_css 'svg'
      end

      it 'renders edit as pencil from Lucide' do
        render_inline(described_class.new('edit'))

        expect(page).to have_css 'span.icon-component'
        expect(page).to have_css 'svg'
      end
    end

    context 'with kept icons (brands)' do
      it 'renders brand icons from kept set' do
        render_inline(described_class.new('visa'))

        expect(page).to have_css 'span.icon-component'
        expect(page).to have_css 'svg'
      end

      it 'renders social media icons from kept set' do
        render_inline(described_class.new('whatsapp'))

        expect(page).to have_css 'span.icon-component'
        expect(page).to have_css 'svg'
      end
    end

    context 'with legacy icons' do
      it 'falls back to legacy icons when not in Lucide or kept' do
        # 'poo' is a legacy icon that might not be mapped
        render_inline(described_class.new('poo'))

        expect(page).to have_css 'span.icon-component'
        expect(page).to have_css 'svg'
      end
    end

    context 'with invalid icon name' do
      it 'raises IconNotAvailable error' do
        expect do
          render_inline(described_class.new('definitely-not-an-icon-xyz'))
        end.to raise_error(Bali::Icon::Options::IconNotAvailable)
      end
    end
  end

  describe 'custom tag' do
    it 'renders with custom tag_name' do
      render_inline(described_class.new('snowflake', tag_name: :div))

      expect(page).to have_css 'div.icon-component'
    end
  end
end
