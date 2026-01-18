# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe 'TimeFields' do
    describe 'constants' do
      it 'defines TIME_WRAPPER_OPTIONS' do
        expect(described_class::TimeFields::TIME_WRAPPER_OPTIONS).to eq(
          'data-datepicker-enable-time-value': true,
          'data-datepicker-no-calendar-value': true
        )
      end

      it 'freezes TIME_WRAPPER_OPTIONS' do
        expect(described_class::TimeFields::TIME_WRAPPER_OPTIONS).to be_frozen
      end

      it 'defines OPTION_TO_DATA_ATTRIBUTE mapping' do
        expect(described_class::TimeFields::OPTION_TO_DATA_ATTRIBUTE).to eq(
          seconds: 'data-datepicker-enable-seconds-value',
          default_date: 'data-datepicker-default-date-value',
          min_time: 'data-datepicker-min-time-value',
          max_time: 'data-datepicker-max-time-value'
        )
      end

      it 'freezes OPTION_TO_DATA_ATTRIBUTE' do
        expect(described_class::TimeFields::OPTION_TO_DATA_ATTRIBUTE).to be_frozen
      end
    end
  end

  describe '#time_field_group' do
    let(:time_group) { builder.time_field_group(:duration) }

    it 'renders the input and label within a wrapper' do
      expect(time_group).to have_css '#field-duration.fieldset'
    end

    it 'renders the label' do
      expect(time_group).to have_css 'legend.fieldset-legend', text: 'Duration'
    end

    it 'renders the input' do
      expect(time_group).to have_css 'input#movie_duration[name="movie[duration]"]'
    end
  end

  describe '#time_field' do
    before { @options = {} }

    let(:time_field) { builder.time_field(:duration, @options) }

    it 'renders the field with the datepicker controller' do
      expect(time_field).to have_css '.fieldset[data-controller="datepicker"]'
    end

    it 'renders the input' do
      expect(time_field).to have_css 'input#movie_duration[name="movie[duration]"]'
    end

    it 'renders with datepicker time enabled' do
      expect(time_field).to have_css '.fieldset[data-datepicker-enable-time-value="true"]'
    end

    it 'renders with datepicker calendar disabled' do
      expect(time_field).to have_css '.fieldset[data-datepicker-no-calendar-value="true"]'
    end

    it 'renders with datepicker seconds enabled' do
      @options.merge!(seconds: true)
      expect(time_field).to have_css '.fieldset[data-datepicker-enable-seconds-value="true"]'
    end

    it 'renders with datepicker default date' do
      @options.merge!(default_date: '1983-04-13')
      expect(time_field).to have_css(
        '.fieldset[data-datepicker-default-date-value="1983-04-13"]'
      )
    end

    it 'renders with datepicker min time' do
      @options.merge!(min_time: '08:00')
      expect(time_field).to have_css '.fieldset[data-datepicker-min-time-value="08:00"]'
    end

    it 'renders with datepicker max time' do
      @options.merge!(max_time: '23:00')
      expect(time_field).to have_css '.fieldset[data-datepicker-max-time-value="23:00"]'
    end

    context 'with existing wrapper_options' do
      subject(:time_field) do
        builder.time_field(:duration, wrapper_options: { 'data-custom': 'value' })
      end

      it 'merges with time wrapper options' do
        expect(time_field).to have_css '.fieldset[data-custom="value"]'
        expect(time_field).to have_css '.fieldset[data-datepicker-enable-time-value="true"]'
      end
    end

    context 'does not mutate input options' do
      it 'preserves original options hash' do
        original_options = { seconds: true }
        options_copy = original_options.dup
        builder.time_field(:duration, original_options)
        expect(original_options).to eq(options_copy)
      end
    end
  end
end
