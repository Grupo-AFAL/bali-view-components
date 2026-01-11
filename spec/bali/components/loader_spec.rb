# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Loader::Component, type: :component do
  describe 'basic rendering' do
    it 'renders loader with default options' do
      render_inline(described_class.new)

      expect(page).to have_css 'div.loader-component'
      expect(page).to have_css 'span.loading.loading-spinner.loading-lg'
      expect(page).to have_css 'h2', text: 'Loading...'
    end

    it 'renders loader with custom text' do
      render_inline(described_class.new(text: 'Cargando'))

      expect(page).to have_css 'h2', text: 'Cargando'
    end

    it 'hides text when hide_text option is true' do
      render_inline(described_class.new(hide_text: true))

      expect(page).not_to have_css 'h2'
    end
  end

  describe 'types' do
    it 'renders spinner type by default' do
      render_inline(described_class.new)

      expect(page).to have_css 'span.loading.loading-spinner'
    end

    %i[spinner dots ring ball bars infinity].each do |type|
      it "renders #{type} type" do
        render_inline(described_class.new(type: type, hide_text: true))

        expect(page).to have_css "span.loading.loading-#{type}"
      end
    end
  end

  describe 'sizes' do
    %i[xs sm md lg xl].each do |size|
      it "renders #{size} size" do
        render_inline(described_class.new(size: size, hide_text: true))

        expect(page).to have_css "span.loading.loading-#{size}"
      end
    end
  end

  describe 'colors' do
    %i[primary secondary accent info success warning error].each do |color|
      it "renders #{color} color" do
        render_inline(described_class.new(color: color, hide_text: true))

        expect(page).to have_css "span.loading.text-#{color}"
      end
    end
  end
end
