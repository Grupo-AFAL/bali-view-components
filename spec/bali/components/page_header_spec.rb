# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::PageHeader::Component, type: :component do
  before { @options = {} }
  let(:component) { Bali::PageHeader::Component.new(**@options) }

  describe 'rendering' do
    context 'with title and subtitle as params' do
      before { @options.merge!(title: 'Title', subtitle: 'Subtitle') }

      it 'renders' do
        render_inline(component)

        expect(page).to have_css '.level-left h1.title', text: 'Title'
        expect(page).to have_css '.level-left p.subtitle', text: 'Subtitle'
      end
    end

    context 'with title and subtitle as slots' do
      context 'when using text param' do
        it 'renders' do
          render_inline(component) do |c|
            c.title('Title')
            c.subtitle('Subtitle')
            'Right content'
          end

          expect(page).to have_css '.level-left h1.title', text: 'Title'
          expect(page).to have_css '.level-left p.subtitle', text: 'Subtitle'
          expect(page).to have_css '.level-right', text: 'Right content'
        end
      end

      context 'when using blocks' do
        it 'renders' do
          render_inline(component) do |c|
            c.title { '<h2 class="title">Title</h2>'.html_safe }
            c.subtitle { '<p class="subtitle">Subtitle</p>'.html_safe }
            'Right content'
          end

          expect(page).to have_css '.level-left h2.title', text: 'Title'
          expect(page).to have_css '.level-left p.subtitle', text: 'Subtitle'
          expect(page).to have_css '.level-right', text: 'Right content'
        end
      end
    end
  end
end
