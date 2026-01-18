# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Tags::Component, type: :component do
  describe 'container rendering' do
    it 'renders with default gap' do
      render_inline(described_class.new) do |c|
        c.with_item(text: 'Tag 1')
        c.with_item(text: 'Tag 2')
      end

      expect(page).to have_css 'div.tags-component.flex.flex-wrap.items-center.gap-2'
    end

    it 'renders with custom gap' do
      render_inline(described_class.new(gap: :lg)) do |c|
        c.with_item(text: 'Tag')
      end

      expect(page).to have_css 'div.tags-component.gap-4'
    end

    it 'renders with no gap' do
      render_inline(described_class.new(gap: :none)) do |c|
        c.with_item(text: 'Tag')
      end

      expect(page).to have_css 'div.tags-component.gap-0'
    end

    it 'does not render when empty' do
      render_inline(described_class.new)

      expect(page).not_to have_css 'div.tags-component'
    end

    it 'passes through custom classes' do
      render_inline(described_class.new(class: 'my-custom-class')) do |c|
        c.with_item(text: 'Tag')
      end

      expect(page).to have_css 'div.tags-component.my-custom-class'
    end

    it 'passes through data attributes' do
      render_inline(described_class.new(data: { testid: 'tags' })) do |c|
        c.with_item(text: 'Tag')
      end

      expect(page).to have_css 'div.tags-component[data-testid="tags"]'
    end
  end

  describe 'tag items' do
    it 'renders multiple tags' do
      render_inline(described_class.new) do |c|
        c.with_item(text: 'First')
        c.with_item(text: 'Second')
        c.with_item(text: 'Third')
      end

      expect(page).to have_css 'div.badge', count: 3
      expect(page).to have_text 'First'
      expect(page).to have_text 'Second'
      expect(page).to have_text 'Third'
    end

    it 'renders tag with color' do
      render_inline(described_class.new) do |c|
        c.with_item(text: 'Primary', color: :primary)
      end

      expect(page).to have_css 'div.badge.badge-primary', text: 'Primary'
    end

    it 'renders tag with size' do
      render_inline(described_class.new) do |c|
        c.with_item(text: 'Small', size: :sm)
      end

      expect(page).to have_css 'div.badge.badge-sm', text: 'Small'
    end

    it 'renders tag with style' do
      render_inline(described_class.new) do |c|
        c.with_item(text: 'Outline', style: :outline)
      end

      expect(page).to have_css 'div.badge.badge-outline', text: 'Outline'
    end

    it 'renders tag with rounded' do
      render_inline(described_class.new) do |c|
        c.with_item(text: 'Rounded', rounded: true)
      end

      expect(page).to have_css 'div.badge.rounded-full', text: 'Rounded'
    end

    it 'renders link tags when href provided' do
      render_inline(described_class.new) do |c|
        c.with_item(text: 'Link Tag', href: '/example')
      end

      expect(page).to have_css 'a.badge[href="/example"]', text: 'Link Tag'
    end

    it 'allows individual tag styling' do
      render_inline(described_class.new) do |c|
        c.with_item(text: 'Primary', color: :primary)
        c.with_item(text: 'Error Outline', color: :error, style: :outline)
        c.with_item(text: 'Success Rounded', color: :success, rounded: true)
      end

      expect(page).to have_css '.badge-primary', text: 'Primary'
      expect(page).to have_css '.badge-error.badge-outline', text: 'Error Outline'
      expect(page).to have_css '.badge-success.rounded-full', text: 'Success Rounded'
    end
  end

  describe 'GAPS constant' do
    it 'has frozen hash' do
      expect(described_class::GAPS).to be_frozen
    end

    it 'contains all gap options' do
      expect(described_class::GAPS.keys).to contain_exactly(:none, :xs, :sm, :md, :lg)
    end
  end
end
