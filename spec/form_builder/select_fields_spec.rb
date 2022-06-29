# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#select_group' do
    it 'renders an input' do
      expect(builder.select_group(:status, Movie.statuses.to_a)).to include(
        '<div id="field-status" class="field-group-wrapper-component field ">'\
        '<label class="label " for="movie_status">'\
        'Status</label><div class="control "><div id="status_select_div" class="select ">'\
        "<select name=\"movie[status]\" id=\"movie_status\"><option value=\"0\">draft</option>\n"\
        '<option value="1">done</option></select></div></div></div>'
      )
    end
  end

  describe '#select_field' do
    it 'renders an input' do
      expect(builder.select_field(:status, Movie.statuses.to_a)).to include(
        '<div class="control "><div id="status_select_div" class="select ">'\
        "<select name=\"movie[status]\" id=\"movie_status\"><option value=\"0\">draft</option>\n"\
        '<option value="1">done</option></select></div></div>'
      )
    end
  end
end
