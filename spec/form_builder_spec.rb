# frozen_string_literal: true

require 'rails_helper'

class TestHelper < ActionView::Base; end

RSpec.describe Bali::FormBuilder do
  let(:helper) { TestHelper.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil) }
  let(:resource) { Movie.new }
  let(:builder) { Bali::FormBuilder.new :movie, resource, helper, {} }

  describe '#text_field_group' do
    it 'renders an input' do
      expect(builder.text_field_group(:name)).to include(
        '<div id="field-name" class="field "><label class="label " for="movie_name">Name</label>'\
        '<div class="control "><input class="input " type="text" name="movie[name]" '\
        'id="movie_name" /></div></div>'
      )
    end
  end

  describe '#text_field' do
    it 'renders an input' do
      expect(builder.text_field(:name)).to include(
        '<div class="control ">'\
        '<input class="input " type="text" name="movie[name]" id="movie_name" />'\
        '</div>'
      )
    end
  end

  describe '#boolean_field_group' do
    it 'renders an input' do
      expect(builder.boolean_field_group(:indie)).to include(
        '<div class="field"><label class="label " for="movie_indie">'\
        '<input name="movie[indie]" type="hidden" value="0" autocomplete="off" />'\
        '<input type="checkbox" value="1" name="movie[indie]" id="movie_indie" /> '\
        'Indie</label></div>'
      )
    end
  end

  describe '#boolean_field' do
    it 'renders an input' do
      expect(builder.boolean_field(:indie)).to include(
        '<label class="label " for="movie_indie">'\
        '<input name="movie[indie]" type="hidden" value="0" autocomplete="off" />'\
        '<input type="checkbox" value="1" name="movie[indie]" id="movie_indie" /> '\
        'Indie</label>'
      )
    end
  end

  describe '#currency_field_group' do
    it 'renders an input' do
      expect(builder.currency_field_group(:budget)).to include(
        '<div id="field-budget" class="field ">'\
        '<label class="label " for="movie_budget">Budget</label>'\
        '<div class="field has-addons"><div class="control">'\
        '<span class="button is-static">$</span></div>'\
        '<div class="control "><input placeholder="0" step="0.01" '\
        'pattern="^(\\d+|\\d{1,3}(,\\d{3})*)(\\.\\d+)?$" class="input " type="text" '\
        'name="movie[budget]" id="movie_budget" /></div></div></div>'
      )
    end
  end

  describe '#date_field_group' do
    it 'renders an input' do
      expect(builder.date_field_group(:release_date)).to include(
        '<div id="field-release_date" class="field ">'\
        '<label class="label " for="movie_release_date">Release date</label>'\
        '<div class="field flatpickr" data-controller="datepicker" '\
        'data-datepicker-locale-value="en"><div class="control is-fullwidth ">'\
        '<input control_class="is-fullwidth " class="input " type="text" '\
        'name="movie[release_date]" id="movie_release_date" /></div></div></div>'
      )
    end
  end

  describe '#datetime_field_group' do
    it 'renders an input' do
      expect(builder.datetime_field_group(:release_date)).to include(
        '<div id="field-release_date" class="field ">'\
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

  describe '#email_field_group' do
    it 'renders an input' do
      expect(builder.email_field_group(:contact_email)).to include(
        '<div id="field-contact_email" class="field ">'\
        '<label class="label " for="movie_contact_email">Contact email</label>'\
        '<div class="control "><input class="input " type="email" '\
        'name="movie[contact_email]" id="movie_contact_email" /></div></div>'
      )
    end
  end

  describe '#email_field' do
    it 'renders an input' do
      expect(builder.email_field(:contact_email)).to include(
        '<div class="control "><input class="input " type="email" '\
        'name="movie[contact_email]" id="movie_contact_email" /></div>'
      )
    end
  end

  describe '#file_field_group' do
    it 'renders an input' do
      expect(builder.file_field_group(:cover_photo)).to include(
        '<div class="field file has-name" data-controller="file-input" '\
        'data-file-input-non-selected-text-value="No file selected"><label class="file-label"'\
        '><div class="control "><input class="input file-input" '\
        'data-action="file-input#onChange" type="file" name="movie[cover_photo]" '\
        'id="movie_cover_photo" /></div><span class="file-cta"><span class="file-icon">'\
        "<span class=\"icon-component icon\">\n        <svg viewBox=\"0 0 512 512\" "\
        "class=\"svg-inline\">\n          <path fill=\"currentColor\"\n            "\
        "d=\"M296 384h-80c-13.3 0-24-10.7-24-24V192h-87.7c-17.8 0-26.7-21.5-14.1-34.1L242.3\n    "\
        "        5.7c7.5-7.5 19.8-7.5 27.3 0l152.2 152.2c12.6 12.6 3.7 34.1-14.1 34.1H320v168c0\n"\
        '            13.3-10.7 24-24 24zm216-8v112c0 13.3-10.7 24-24 24H24c-13.3 0-24-10.7-24-24V'\
        "376c0-13.3\n            10.7-24 24-24h136v8c0 30.9 25.1 56 56 56h80c30.9 0 56-25.1 56-56"\
        "v-8h136c13.3 0 24 10.7\n            24 24zm-124 88c0-11-9-20-20-20s-20 9-20 20 9 20 20 "\
        "20 20-9 20-20zm64\n            0c0-11-9-20-20-20s-20 9-20 20 9 20 20 20 20-9 20-20z\">"\
        "\n          </path>\n        </svg>\n      </span></span><span class=\"file-label\">"\
        'Choose file</span></span><span class="file-name" data-file-input-target="value">No'\
        ' file selected</span></label></div>'
      )
    end
  end

  describe '#file_field' do
    it 'renders an input' do
      expect(builder.file_field(:cover_photo)).to include(
        '<div class="control "><input class="input " type="file" '\
        'name="movie[cover_photo]" id="movie_cover_photo" /></div>'
      )
    end
  end

  describe '#number_field_group' do
    it 'renders an input' do
      expect(builder.number_field_group(:budget)).to include(
        '<div id="field-budget" class="field "><label class="label " for="movie_budget">'\
        'Budget</label><div class="control "><input class="input " type="number" '\
        'name="movie[budget]" id="movie_budget" /></div></div>'
      )
    end
  end

  describe '#number_field' do
    it 'renders an input' do
      expect(builder.number_field(:budget)).to include(
        '<div class="control "><input class="input " type="number" name="movie[budget]"'\
        ' id="movie_budget" /></div>'
      )
    end
  end

  describe '#password_field_group' do
    it 'renders an input' do
      expect(builder.password_field_group(:budget)).to include(
        '<div id="field-budget" class="field "><label class="label " for="movie_budget">'\
        'Budget</label><div class="control "><input class="input " type="password" '\
        'name="movie[budget]" id="movie_budget" /></div></div>'
      )
    end
  end

  describe '#password_field' do
    it 'renders an input' do
      expect(builder.password_field(:budget)).to include(
        '<div class="control "><input class="input " type="password" name="movie[budget]"'\
        ' id="movie_budget" /></div>'
      )
    end
  end

  describe '#percentage_field_group' do
    it 'renders an input' do
      expect(builder.percentage_field_group(:budget)).to include(
        '<div id="field-budget" class="field "><label class="label " for="movie_budget">'\
        'Budget</label><div class="field has-addons"><div class="control "><input '\
        'placeholder="0" step="0.01" pattern="^(\\d+|\\d{1,3}(,\\d{3})*)(\\.\\d+)?$" '\
        'class="input " type="text" name="movie[budget]" id="movie_budget" /></div><div '\
        'class="control"><span class="button is-static">%</span></div></div></div>'
      )
    end
  end

  describe '#radio_field_group' do
    it 'renders an input' do
      expect(builder.radio_field_group(:status, Movie.statuses.to_a)).to include(
        '<div class="control "><label class="radio" for="movie_status_0">'\
        '<input type="radio" value="0" name="movie[status]" id="movie_status_0" />draft'\
        '</label><label class="radio" for="movie_status_1"><input type="radio" value="1"'\
        ' name="movie[status]" id="movie_status_1" />done</label></div>'
      )
    end
  end

  describe '#time_field_group' do
    it 'renders an input' do
      expect(builder.time_field_group(:duration)).to include(
        '<div id="field-duration" class="field "><label class="label " '\
        'for="movie_duration">Duration</label><div class="field flatpickr" '\
        'data-controller="datepicker" data-datepicker-locale-value="en" '\
        'data-datepicker-enable-time-value="true" data-datepicker-no-calendar-value="true">'\
        '<div class="control is-fullwidth "><input control_class="is-fullwidth " '\
        'class="input " type="text" value="2022-06-28 00:00:00" name="movie[duration]" '\
        'id="movie_duration" /></div></div></div>'
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
        'value="2022-06-28 00:00:00" name="movie[duration]" id="movie_duration" />'\
        '</div></div>'
      )
    end
  end

  describe '#time_zone_select_group' do
    it 'renders an input' do
      expect(builder.time_zone_select_group(:release_date)).to include(
        '<label class="label " for="movie_release_date">Release date</label>'\
        '<div class="control "><div class="select "><select class="input " '\
        'name="movie[release_date]" id="movie_release_date">'
      )
    end
  end

  describe '#time_zone_select' do
    it 'renders an input' do
      expect(builder.time_zone_select(:release_date)).to include(
        '<div class="control "><div class="select "><select class="input " '\
        'name="movie[release_date]" id="movie_release_date">'
      )
    end
  end
end
