# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#date_field_group' do
    let(:date_field_group) { builder.date_field_group(:release_date) }

    it 'renders a label and input within a wrapper' do
      expect(date_field_group).to have_css 'div.field.field-group-wrapper-component'
    end

    it 'renders a label' do
      expect(date_field_group).to have_css 'label[for="movie_release_date"]', text: 'Release date'
    end

    it 'renders a field with datepicker controller' do
      expect(date_field_group).to have_css 'div[data-controller="datepicker"]'
    end

    it 'renders an input' do
      expect(date_field_group).to have_css 'input#movie_release_date[name="movie[release_date]"]'
    end
  end
end
