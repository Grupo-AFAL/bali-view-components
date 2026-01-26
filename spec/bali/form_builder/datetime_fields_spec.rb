# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe 'DatetimeFields::DATETIME_WRAPPER_OPTIONS' do
    it 'is frozen' do
      expect(Bali::FormBuilder::DatetimeFields::DATETIME_WRAPPER_OPTIONS).to be_frozen
    end

    it 'has enable-time set to true' do
      expect(Bali::FormBuilder::DatetimeFields::DATETIME_WRAPPER_OPTIONS).to include(
        'data-datepicker-enable-time-value': true
      )
    end
  end

  describe '#datetime_field_group' do
    subject(:datetime_field_group) { builder.datetime_field_group(:release_date) }

    it 'renders a label and input within a wrapper' do
      expect(datetime_field_group).to have_css('.fieldset')
    end

    it 'renders a label' do
      expect(datetime_field_group).to have_css('legend.fieldset-legend', text: 'Release date')
    end

    it 'renders a field with a datepicker controller' do
      expect(datetime_field_group).to have_css('.fieldset[data-controller="datepicker"]')
    end

    it 'renders a field with datepicker time enabled' do
      expect(datetime_field_group)
        .to have_css('.fieldset[data-datepicker-enable-time-value="true"]')
    end

    it 'renders a field with datepicker locale value' do
      expect(datetime_field_group).to have_css('.fieldset[data-datepicker-locale-value="en"]')
    end

    it 'renders an input' do
      expect(datetime_field_group)
        .to have_css('input#movie_release_date[name="movie[release_date]"]')
    end
  end

  describe '#datetime_select_group' do
    it 'is an alias for datetime_field_group' do
      expect(builder.method(:datetime_select_group).original_name).to eq(:datetime_field_group)
    end
  end

  describe '#datetime_field' do
    subject(:datetime_field) { builder.datetime_field(:release_date) }

    it 'renders a field with a datepicker controller' do
      expect(datetime_field).to have_css('.fieldset[data-controller="datepicker"]')
    end

    it 'renders a field with datepicker time enabled' do
      expect(datetime_field).to have_css('.fieldset[data-datepicker-enable-time-value="true"]')
    end

    it 'renders a field with datepicker locale value' do
      expect(datetime_field).to have_css('.fieldset[data-datepicker-locale-value="en"]')
    end

    it 'renders an input' do
      expect(datetime_field).to have_css('input#movie_release_date[name="movie[release_date]"]')
    end

    it 'does not mutate the passed options hash' do
      original_options = { class: 'my-class' }
      options_copy = original_options.dup
      builder.datetime_field(:release_date, original_options)
      expect(original_options).to eq(options_copy)
    end

    context 'with existing wrapper_options' do
      subject(:datetime_field) do
        builder.datetime_field(:release_date, wrapper_options: { 'data-custom': 'value' })
      end

      it 'merges with datetime wrapper options' do
        expect(datetime_field).to have_css('.fieldset[data-custom="value"]')
        expect(datetime_field).to have_css('.fieldset[data-datepicker-enable-time-value="true"]')
      end
    end
  end
end
