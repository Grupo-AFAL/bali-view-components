# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#text_area_group' do
    it 'renders an input' do
      expect(builder.text_area_group(:synopsis)).to include(
        '<div id="field-synopsis" class="field-group-wrapper-component field ">'\
        '<label class="label " for="movie_synopsis">Synopsis</label>'\
        '<div class="control "><textarea class="textarea " name="movie[synopsis]"'\
        " id=\"movie_synopsis\">\n</textarea></div></div>"
      )
    end
  end

  describe '#text_area' do
    it 'renders an input' do
      expect(builder.text_area(:synopsis)).to include(
        '<div class="control "><textarea class="textarea " name="movie[synopsis]" '\
        "id=\"movie_synopsis\">\n</textarea></div>"
      )
    end
  end
end
