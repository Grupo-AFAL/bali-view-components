# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Message::Component, type: :component do
  it 'renders message component with alert role' do
    render_inline(described_class.new) { 'Message content' }

    expect(page).to have_css 'div.message-component.alert[role="alert"]', text: 'Message content'
  end

  it 'applies BASE_CLASSES' do
    render_inline(described_class.new) { 'Content' }

    expect(page).to have_css 'div.alert.message-component'
  end

  describe 'colors' do
    described_class::COLORS.each do |color, css_class|
      it "renders #{color} color with #{css_class}" do
        render_inline(described_class.new(color: color)) { 'Content' }
        expect(page).to have_css "div.alert.#{css_class}"
      end
    end

    it 'falls back to primary for unknown color' do
      render_inline(described_class.new(color: :unknown)) { 'Content' }
      expect(page).to have_css 'div.alert.alert-info'
    end
  end

  describe 'sizes' do
    it 'renders small size' do
      render_inline(described_class.new(size: :small)) { 'Content' }
      expect(page).to have_css 'div.alert.text-sm'
    end

    it 'renders regular size (no extra class)' do
      render_inline(described_class.new(size: :regular)) { 'Content' }
      expect(page).to have_css 'div.alert'
      expect(page).not_to have_css 'div.text-sm'
      expect(page).not_to have_css 'div.text-lg'
    end

    it 'renders medium size' do
      render_inline(described_class.new(size: :medium)) { 'Content' }
      expect(page).to have_css 'div.alert.text-base'
    end

    it 'renders large size' do
      render_inline(described_class.new(size: :large)) { 'Content' }
      expect(page).to have_css 'div.alert.text-lg'
    end

    it 'falls back to regular for unknown size' do
      render_inline(described_class.new(size: :unknown)) { 'Content' }
      expect(page).to have_css 'div.alert'
    end
  end

  describe 'with title' do
    it 'renders title in bold span' do
      render_inline(described_class.new(title: 'My Title')) { 'Content' }

      expect(page).to have_css 'span.font-bold', text: 'My Title'
      expect(page).to have_css 'div.flex.flex-col.gap-1'
    end

    it 'renders content alongside title' do
      render_inline(described_class.new(title: 'Header')) { 'Body text' }

      expect(page).to have_css 'span.font-bold', text: 'Header'
      expect(page).to have_text 'Body text'
    end
  end

  describe 'with header slot' do
    it 'renders custom header' do
      render_inline(described_class.new) do |c|
        c.with_header { 'Custom Header' }
        'Body content'
      end

      expect(page).to have_css 'div.flex.flex-col.gap-1'
      expect(page).to have_text 'Custom Header'
      expect(page).to have_text 'Body content'
    end

    it 'prefers title over header slot' do
      render_inline(described_class.new(title: 'Title wins')) do |c|
        c.with_header { 'Header slot' }
        'Content'
      end

      expect(page).to have_css 'span.font-bold', text: 'Title wins'
      expect(page).not_to have_text 'Header slot'
    end
  end

  describe 'without title or header' do
    it 'renders content directly' do
      render_inline(described_class.new) { 'Simple message' }

      expect(page).to have_css 'div.alert > span', text: 'Simple message'
      expect(page).not_to have_css 'div.flex.flex-col'
    end
  end

  describe 'options passthrough' do
    it 'accepts custom classes' do
      render_inline(described_class.new(class: 'custom-class')) { 'Content' }

      expect(page).to have_css 'div.alert.custom-class'
    end

    it 'accepts data attributes' do
      render_inline(described_class.new(data: { testid: 'my-message' })) { 'Content' }

      expect(page).to have_css 'div.alert[data-testid="my-message"]'
    end

    it 'accepts id attribute' do
      render_inline(described_class.new(id: 'unique-message')) { 'Content' }

      expect(page).to have_css 'div.alert#unique-message'
    end
  end
end
