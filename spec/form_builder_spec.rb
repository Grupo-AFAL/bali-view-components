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

  describe '#search_field_group' do
    it 'renders an input' do
      expect(builder.search_field_group(:name)).to include(
        "<div id=\"field-name\" class=\"field \"><label class=\"label \" for=\"movie_name\">Name"\
        "</label><div class=\"field has-addons\"><div class=\"control \"><input "\
        "placeholder=\"Search...\" class=\"input \" type=\"text\" name=\"movie[name]\" "\
        "id=\"movie_name\" /></div><div class=\"control\"><button type=\"submit\" "\
        "class=\"button is-info\"><span class=\"icon-component icon\">\n        <svg "\
        "viewBox=\"0 0 512 512\" class=\"svg-inline\">\n          <path fill=\"currentColor\"\n"\
        "            d=\"M508.5 481.6l-129-129c-2.3-2.3-5.3-3.5-8.5-3.5h-10.3C395 312 416 262.5 "\
        "416 208 416 93.1 322.9 0 208 0S0 93.1 0 208s93.1 208 208 208c54.5 0 104-21 141.1-55.2V3"\
        "71c0 3.2 1.3 6.2 3.5 8.5l129 129c4.7 4.7 12.3 4.7 17 0l9.9-9.9c4.7-4.7 4.7-12.3 0-17zM2"\
        "08 384c-97.3 0-176-78.7-176-176S110.7 32 208 32s176 78.7 176 176-78.7 176-176 176z\"\n  "\
        "          class=\"\"></path>\n        </svg>\n      </span></button></div></div></div>"
      )
    end
  end

  describe '#select_group' do
    it 'renders an input' do
      expect(builder.select_group(:status, Movie.statuses.to_a)).to include(
        "<div id=\"field-status\" class=\"field \"><label class=\"label \" for=\"movie_status\">"\
        "Status</label><div class=\"control \"><div id=\"status_select_div\" class=\"select \">"\
        "<select name=\"movie[status]\" id=\"movie_status\"><option value=\"0\">draft</option>\n"\
        "<option value=\"1\">done</option></select></div></div></div>"
      )
    end
  end

  describe '#select_field' do
    it 'renders an input' do
      expect(builder.select_field(:status, Movie.statuses.to_a)).to include(
        "<div class=\"control \"><div id=\"status_select_div\" class=\"select \">"\
        "<select name=\"movie[status]\" id=\"movie_status\"><option value=\"0\">draft</option>\n"\
        "<option value=\"1\">done</option></select></div></div>"
      )
    end
  end

  describe '#slim_select_group' do
    it 'renders an input' do
      expect(builder.slim_select_group(:status, Movie.statuses.to_a)).to include(
        "<div id=\"field-status\" class=\"field \"><label class=\"label \" for=\"movie_status\">"\
        "Status</label><div class=\"control \"><div id=\"status_select_div\" "\
        "class=\"slim-select\" data-controller=\"slim-select\" data-slim-select-close-on-select-"\
        "value=\"true\" data-slim-select-allow-deselect-option-value=\"false\" data-slim-select-"\
        "add-items-value=\"false\" data-slim-select-show-content-value=\"auto\" data-slim-select-"\
        "show-search-value=\"true\" data-slim-select-search-placeholder-value=\"Buscar\" data-"\
        "slim-select-add-to-body-value=\"false\" data-slim-select-select-all-text-value=\"Select"\
        " all\" data-slim-select-deselect-all-text-value=\"Deselect all\"><select data-slim-"\
        "select-target=\"select\" class=\"select\" name=\"movie[status]\" id=\"movie_status\">"\
        "<option value=\"0\">draft</option>\n<option value=\"1\">done</option></select></div>"\
        "</div></div>"
      )
    end
  end

  describe '#slim_select_field' do
    it 'renders an input' do
      expect(builder.slim_select_field(:status, Movie.statuses.to_a)).to include(
        "<div class=\"control \"><div id=\"status_select_div\" class=\"slim-select\" "\
        "data-controller=\"slim-select\" data-slim-select-close-on-select-value=\"true\" "\
        "data-slim-select-allow-deselect-option-value=\"false\" data-slim-select-add-items"\
        "-value=\"false\" data-slim-select-show-content-value=\"auto\" data-slim-select-show"\
        "-search-value=\"true\" data-slim-select-search-placeholder-value=\"Buscar\" data-slim"\
        "-select-add-to-body-value=\"false\" data-slim-select-select-all-text-value=\"Select "\
        "all\" data-slim-select-deselect-all-text-value=\"Deselect all\"><select data-slim-"\
        "select-target=\"select\" class=\"select\" name=\"movie[status]\" id=\"movie_status\">"\
        "<option value=\"0\">draft</option>\n<option value=\"1\">done</option></select></div>"\
        "</div>"
      )
    end
  end

  describe '#step_number_field_group' do
    it 'renders an input' do
      expect(builder.step_number_field_group(:duration)).to include(
        "<div id=\"field-duration\" class=\"field \"><label class=\"label \" "\
        "for=\"movie_duration\">Duration</label><div class=\"field has-addons\" "\
        "data-controller=\"step-number-input\"><div class=\"control\"><a class=\"button\" "\
        "data-action=\"step-number-input#subtract\" data-step-number-input-target=\"subtract\" "\
        "title=\"subtract\" href=\"\"><span class=\"icon-component icon\">\n        <svg "\
        "viewBox=\"0 0 14 2\" class=\"svg-inline\" fill=\"none\">\n          <path d=\"M0.599609 "\
        "0H13.3996V1.60001H0.599609V0Z\" fill=\"currentColor\"/>\n        </svg>\n      </span>"\
        "</a></div><div class=\"control\"><div class=\"control \"><input data-step-number-input-"\
        "target=\"input\" class=\"input \" type=\"number\" value=\"2022-06-28 00:00:00\" "\
        "name=\"movie[duration]\" id=\"movie_duration\" /></div></div><div class=\"control\"><a "\
        "class=\"button\" data-action=\"step-number-input#add\" data-step-number-input-target"\
        "=\"add\" title=\"add\" href=\"\"><span class=\"icon-component icon\">\n        <svg "\
        "viewBox=\"0 0 448 512\" class=\"svg-inline\">\n          <path fill=\"currentColor\"\n "\
        "           d=\"M416 208H272V64c0-17.67-14.33-32-32-32h-32c-17.67 0-32 14.33-32 32v144H3"\
        "2c-17.67 0-32 14.33-32 32v32c0 17.67 14.33 32 32 32h144v144c0 17.67 14.33 32 32 32h32c1"\
        "7.67 0 32-14.33 32-32V304h144c17.67 0 32-14.33 32-32v-32c0-17.67-14.33-32-32-32z\"\n   "\
        "         class=\"\"></path>\n        </svg>\n      </span></a></div></div></div>"
      )
    end
  end

  describe '#step_number_field' do
    it 'renders an input' do
      expect(builder.step_number_field(:duration)).to include(
        "<div class=\"field has-addons\" data-controller=\"step-number-input\"><div "\
        "class=\"control\"><a class=\"button\" data-action=\"step-number-input#subtract\" "\
        "data-step-number-input-target=\"subtract\" title=\"subtract\" href=\"\"><span "\
        "class=\"icon-component icon\">\n        <svg viewBox=\"0 0 14 2\" class=\"svg-inline\" "\
        "fill=\"none\">\n          <path d=\"M0.599609 0H13.3996V1.60001H0.599609V0Z\" "\
        "fill=\"currentColor\"/>\n        </svg>\n      </span></a></div><div class=\"control\">"\
        "<div class=\"control \"><input data-step-number-input-target=\"input\" class=\"input \" "\
        "type=\"number\" value=\"2022-06-28 00:00:00\" name=\"movie[duration]\" "\
        "id=\"movie_duration\" /></div></div><div class=\"control\"><a class=\"button\" "\
        "data-action=\"step-number-input#add\" data-step-number-input-target=\"add\" "\
        "title=\"add\" href=\"\"><span class=\"icon-component icon\">\n        <svg viewBox=\"0 0"\
        " 448 512\" class=\"svg-inline\">\n          <path fill=\"currentColor\"\n            "\
        "d=\"M416 208H272V64c0-17.67-14.33-32-32-32h-32c-17.67 0-32 14.33-32 32v144H32c-17.67 "\
        "0-32 14.33-32 32v32c0 17.67 14.33 32 32 32h144v144c0 17.67 14.33 32 32 32h32c17.67 0 "\
        "32-14.33 32-32V304h144c17.67 0 32-14.33 32-32v-32c0-17.67-14.33-32-32-32z\"\n        "\
        "    class=\"\"></path>\n        </svg>\n      </span></a></div></div>"
      )
    end
  end

  describe '#switch_field_group' do
    it 'renders an input' do
      expect(builder.switch_field_group(:indie, label: 'Indie')).to include(
        "<p>Indie</p><div class=\"field switch\">"
      )
    end
  end

  describe '#switch_field' do
    it 'renders an input' do
      expect(builder.switch_field(:indie)).to include(
        "<div class=\"field switch\">"
      )
    end
  end

  describe '#text_area_group' do
    it 'renders an input' do
      expect(builder.text_area_group(:synopsis)).to include(
        "<div id=\"field-synopsis\" class=\"field \"><label class=\"label \" "\
        "for=\"movie_synopsis\">Synopsis</label><div class=\"control \"><textarea "\
        "class=\"textarea \" name=\"movie[synopsis]\" id=\"movie_synopsis\">\n</textarea>"\
        "</div></div>"
      )
    end
  end

  describe '#text_area' do
    it 'renders an input' do
      expect(builder.text_area(:synopsis)).to include(
        "<div class=\"control \"><textarea class=\"textarea \" name=\"movie[synopsis]\" "\
        "id=\"movie_synopsis\">\n</textarea></div>"
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
