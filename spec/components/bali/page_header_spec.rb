# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::PageHeader::Component, type: :component do
  let(:component) { Bali::PageHeader::Component.new }

  subject { rendered_component }

  describe 'rendering' do
    context 'title' do
      it 'renders' do
        render_inline(component) do |c|
          c.title('Page Header')
        end

        is_expected.to have_css '.level-left h1.title', text: 'Page Header'
      end
    end

    context 'subtitle' do
      it 'renders' do
        render_inline(component) do |c|
          c.title('Page Header')
          c.subtitle('Header subtitle')
        end

        is_expected.to have_css '.level-left h1.title', text: 'Page Header'
        is_expected.to have_css '.level-left p.subtitle', text: 'Header subtitle'
      end
    end

    context 'with contents within level-right' do
      it 'renders' do
        render_inline(component) do |c|
          c.title('Page Header')
          c.subtitle('Header subtitle')

          'Right content'
        end

        is_expected.to have_css '.level-left h1.title', text: 'Page Header'
        is_expected.to have_css '.level-left p.subtitle', text: 'Header subtitle'
        is_expected.to have_css '.level-right', text: 'Right content'
      end
    end
  end
end
