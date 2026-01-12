# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Message::Component, type: :component do
  let(:options) { {} }
  let(:component) { Bali::Message::Component.new(**options) }

  it 'renders message component' do
    render_inline(component) do
      'Message content'
    end

    expect(page).to have_css 'div.message-component.alert', text: 'Message content'
  end

  describe 'colors' do
    it 'renders primary color' do
      render_inline(described_class.new(color: :primary)) { 'Content' }
      expect(page).to have_css 'div.alert.alert-info'
    end

    it 'renders success color' do
      render_inline(described_class.new(color: :success)) { 'Content' }
      expect(page).to have_css 'div.alert.alert-success'
    end

    it 'renders danger color' do
      render_inline(described_class.new(color: :danger)) { 'Content' }
      expect(page).to have_css 'div.alert.alert-error'
    end

    it 'renders warning color' do
      render_inline(described_class.new(color: :warning)) { 'Content' }
      expect(page).to have_css 'div.alert.alert-warning'
    end
  end

  describe 'with title' do
    it 'renders title in header' do
      render_inline(described_class.new(title: 'My Title')) { 'Content' }
      expect(page).to have_css 'span.font-bold', text: 'My Title'
    end
  end
end
