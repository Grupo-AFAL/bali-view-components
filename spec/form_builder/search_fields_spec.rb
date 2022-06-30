# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#search_field_group' do
    let(:search_field_group) { builder.search_field_group(:name) }

    it 'render a label an input within a wrapper' do
      expect(search_field_group).to have_css 'div.field.field-group-wrapper-component'
    end

    it 'renders a label' do
      expect(search_field_group).to have_css 'label[for="movie_name"]', text: 'Name'
    end

    it 'renders an input' do
      expect(search_field_group).to have_css(
        'input#movie_name[name="movie[name]"][placeholder="Search..."]'
      )
    end

    it 'renders an icon' do
      expect(search_field_group).to have_css 'span.icon.icon-component'
    end
  end
end
