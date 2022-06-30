# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#boolean_field_group' do
    let(:boolean_field_group) { builder.boolean_field_group(:indie) }

    it 'renders a label and input within a field wrapper' do
      expect(boolean_field_group).to have_css 'div.field'
    end

    it 'renders a label' do
      expect(boolean_field_group).to have_css '.label[for="movie_indie"]', text: 'Indie'
    end

    it 'renders the inputs' do
      expect(boolean_field_group).to have_css 'input[value="0"]', visible: false
      expect(boolean_field_group).to have_css 'input#movie_indie[value="1"]'
    end
  end

  describe '#boolean_field' do
    let(:boolean_field) { builder.boolean_field(:indie) }

    it 'renders a label' do
      expect(boolean_field).to have_css 'label[for="movie_indie"]', text: 'Indie'
    end

    it 'renders the inputs' do
      expect(boolean_field).to have_css 'input[value="0"]', visible: false
      expect(boolean_field).to have_css 'input#movie_indie[value="1"]'
    end
  end
end
