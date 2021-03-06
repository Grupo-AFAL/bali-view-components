# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#text_field_group' do
    let(:text_field_group) { builder.text_field_group(:name) }

    it 'render a label an input within a wrapper' do
      expect(text_field_group).to have_css 'div.field.field-group-wrapper-component'
    end

    it 'renders a label' do
      expect(text_field_group).to have_css 'label[for="movie_name"]', text: 'Name'
    end

    it 'renders an input' do
      expect(text_field_group).to have_css 'input#movie_name[name="movie[name]"]'
    end
  end

  describe '#text_field' do
    let(:text_field) { builder.text_field(:name) }

    it 'renders a div with control class' do
      expect(text_field).to have_css 'div.control'
    end

    it 'renders an input' do
      expect(text_field).to have_css 'input#movie_name[name="movie[name]"]'
    end
  end
end
