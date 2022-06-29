# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#search_field_group' do
    it 'renders an input' do
      expect(builder.search_field_group(:name)).to include(
        '<div id="field-name" class="field-group-wrapper-component field ">'\
        '<label class="label " for="movie_name">Name'\
        '</label><div class="field has-addons"><div class="control "><input '\
        'placeholder="Search..." class="input " type="text" name="movie[name]" '\
        'id="movie_name" /></div><div class="control"><button type="submit" '\
        "class=\"button is-info\"><span class=\"icon-component icon\">\n        <svg "\
        "viewBox=\"0 0 512 512\" class=\"svg-inline\">\n          <path fill=\"currentColor\"\n"\
        '            d="M508.5 481.6l-129-129c-2.3-2.3-5.3-3.5-8.5-3.5h-10.3C395 312 416 262.5 '\
        '416 208 416 93.1 322.9 0 208 0S0 93.1 0 208s93.1 208 208 208c54.5 0 104-21 141.1-55.2V3'\
        '71c0 3.2 1.3 6.2 3.5 8.5l129 129c4.7 4.7 12.3 4.7 17 0l9.9-9.9c4.7-4.7 4.7-12.3 0-17zM2'\
        "08 384c-97.3 0-176-78.7-176-176S110.7 32 208 32s176 78.7 176 176-78.7 176-176 176z\"\n  "\
        "          class=\"\"></path>\n        </svg>\n      </span></button></div></div></div>"
      )
    end
  end
end
