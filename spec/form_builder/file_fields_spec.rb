# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#file_field_group' do
    it 'renders an input' do
      expect(builder.file_field_group(:cover_photo)).to include(
        '<div class="field file has-name" '\
        'data-controller="file-input" '\
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
end
