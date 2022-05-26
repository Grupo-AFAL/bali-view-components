# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Card::Component, type: :component do
  let(:options) { {} }
  let(:component) do
    Bali::Card::Component.new(title: 'Title', description: 'Description',
                              image: 'https://via.placeholder.com/320x244.png',
                              link: '#')
  end

  subject { rendered_component }

  describe 'rendering' do
    context 'media' do
      it 'renders' do
        render_inline(component) do |c|
          c.media do
            '<div class="media">Media</div>'.html_safe
          end
        end

        is_expected.to have_css '.media', text: 'Media'
      end
    end

    context 'footer_item' do
      it 'renders' do
        render_inline(component) do |c|
          c.footer_item do
            '<a href="#">Footer item with link</a>'.html_safe
          end
        end

        is_expected.to have_css '.card-footer-item a', text: 'Footer item with link'
      end
    end
  end
end
