# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::PageHeader::Component, type: :component do
  let(:component) { Bali::PageHeader::Component.new(**@options) }

  before { @options = {} }

  subject { rendered_component }

  describe 'rendering' do
    context 'title' do
      before { @options = { title: 'Page Header' } }

      it 'renders' do
        render_inline(component)

        is_expected.to have_css '.level-left h1.title', text: 'Page Header'
      end
    end

    context 'subtitle' do
      before { @options = { title: 'Page Header', subtitle: 'Header subtitle' } }

      it 'renders' do
        render_inline(component)

        is_expected.to have_css '.level-left p.subtitle', text: 'Header subtitle'
      end
    end

    context 'with contents within level-right' do
      before { @options = { title: 'Page Header' } }

      it 'renders' do
        render_inline(component) { 'Right content' }

        is_expected.to have_css '.level-right', text: 'Right content'
      end
    end
  end
end
