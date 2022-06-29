# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#datetime_field_group' do
    it 'renders an input' do
      expect(builder.datetime_field_group(:release_date)).to include(
        '<div id="field-release_date" class="field-group-wrapper-component field ">'\
        '<label class="label " for="movie_release_date">Release date</label>'\
        '<div class="field flatpickr" data-controller="datepicker" '\
        'data-datepicker-locale-value="en" data-datepicker-enable-time-value="true">'\
        '<div class="control is-fullwidth "><input control_class="is-fullwidth " '\
        'class="input " type="text" name="movie[release_date]" id="movie_release_date" />'\
        '</div></div></div>'
      )
    end
  end

  describe '#datetime_field' do
    it 'renders an input' do
      expect(builder.datetime_field(:release_date)).to include(
        '<div class="field flatpickr" data-controller="datepicker" '\
        'data-datepicker-locale-value="en" data-datepicker-enable-time-value="true">'\
        '<div class="control is-fullwidth "><input control_class="is-fullwidth " '\
        'class="input " type="text" name="movie[release_date]" id="movie_release_date" />'\
        '</div></div>'
      )
    end
  end
end
