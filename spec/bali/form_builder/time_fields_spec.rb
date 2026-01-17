# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#time_field_group' do
    let(:time_group) { builder.time_field_group(:duration) }

    it 'renders the input and label within a wrapper' do
      expect(time_group).to have_css '#field-duration.form-control'
    end

    it 'renders the label' do
      expect(time_group).to have_css '.label[for="movie_duration"]', text: 'Duration'
    end

    it 'renders the input' do
      expect(time_group).to have_css 'input#movie_duration[name="movie[duration]"]'
    end
  end

  describe '#time_field' do
    before { @options = {} }

    let(:time_field) { builder.time_field(:duration, @options) }

    it 'renders the field with the datepicker controller' do
      expect(time_field).to have_css '.form-control[data-controller="datepicker"]'
    end

    it 'renders the input' do
      expect(time_field).to have_css 'input#movie_duration[name="movie[duration]"]'
    end

    it 'renders with datepicker time enabled' do
      expect(time_field).to have_css '.form-control[data-datepicker-enable-time-value="true"]'
    end

    it 'renders with datepicker calendar disabled' do
      expect(time_field).to have_css '.form-control[data-datepicker-no-calendar-value="true"]'
    end

    it 'renders with datepicker seconds enabled' do
      @options.merge!(seconds: true)
      expect(time_field).to have_css '.form-control[data-datepicker-enable-seconds-value="true"]'
    end

    it 'renders with datepicker default date' do
      @options.merge!(default_date: '1983-04-13')
      expect(time_field).to have_css(
        '.form-control[data-datepicker-default-date-value="1983-04-13"]'
      )
    end

    it 'renders with datepicker min time' do
      @options.merge!(min_time: '08:00')
      expect(time_field).to have_css '.form-control[data-datepicker-min-time-value="08:00"]'
    end

    it 'renders with datepicker max time' do
      @options.merge!(max_time: '23:00')
      expect(time_field).to have_css '.form-control[data-datepicker-max-time-value="23:00"]'
    end
  end
end
