# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#datetime_field_group' do
    let(:datetime_field_group) { builder.datetime_field_group(:release_date) }

    it 'renders a label and input within a wrapper' do
      expect(datetime_field_group).to have_css 'div.field.field-group-wrapper-component'
    end

    it 'renders a label' do
      expect(datetime_field_group).to have_css 'label[for="movie_release_date"]',
                                               text: 'Release date'
    end

    it 'renders a field with a datepicker controller' do
      expect(datetime_field_group).to have_css 'div.field[data-controller="datepicker"]'
    end

    it 'renders a field with datepicker time enabled' do
      expect(datetime_field_group).to have_css 'div.field[data-datepicker-enable-time-value="true"]'
    end

    it 'renders an input' do
      expect(datetime_field_group).to have_css(
        'input#movie_release_date[name="movie[release_date]"]'
      )
    end
  end

  describe '#datetime_field' do
    let(:datetime_field) { builder.datetime_field(:release_date) }

    it 'renders a field with a datepicker controller' do
      expect(datetime_field).to have_css 'div.field[data-controller="datepicker"]'
    end

    it 'renders a field with datepicker time enabled' do
      expect(datetime_field).to have_css 'div.field[data-datepicker-enable-time-value="true"]'
    end

    it 'renders an input' do
      expect(datetime_field).to have_css 'input#movie_release_date[name="movie[release_date]"]'
    end
  end
end
