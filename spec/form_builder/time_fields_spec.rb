# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#time_field_group' do
    it 'renders an input' do
      expect(builder.time_field_group(:duration)).to include(
        '<div id="field-duration" class="field-group-wrapper-component field ">'\
        '<label class="label " for="movie_duration">Duration</label><div '\
        'class="field flatpickr" data-controller="datepicker" data-datepicker-locale'\
        '-value="en" data-datepicker-enable-time-value="true" data-datepicker-no-cale'\
        'ndar-value="true"><div class="control is-fullwidth "><input control_class="is'\
        '-fullwidth " class="input " type="text" value="2022-06-29 00:00:00" name="movie'\
        '[duration]" id="movie_duration" /></div></div></div>'
      )
    end
  end

  describe '#time_field_group' do
    it 'renders an input' do
      expect(builder.time_field(:duration)).to include(
        '<div class="field flatpickr" data-controller="datepicker" '\
        'data-datepicker-locale-value="en" data-datepicker-enable-time-value="true"'\
        ' data-datepicker-no-calendar-value="true"><div class="control is-fullwidth ">'\
        '<input control_class="is-fullwidth " class="input " type="text" '\
        'value="2022-06-29 00:00:00" name="movie[duration]" id="movie_duration" />'\
        '</div></div>'
      )
    end
  end
end
