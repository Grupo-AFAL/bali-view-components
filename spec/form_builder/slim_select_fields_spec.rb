# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#slim_select_group' do
    it 'renders an input' do
      expect(builder.slim_select_group(:status, Movie.statuses.to_a)).to include(
        '<div id="field-status" class="field-group-wrapper-component field ">'\
        '<label class="label " for="movie_status">'\
        'Status</label><div class="control "><div id="status_select_div" '\
        'class="slim-select" data-controller="slim-select" data-slim-select-close-on-select-'\
        'value="true" data-slim-select-allow-deselect-option-value="false" data-slim-select-'\
        'add-items-value="false" data-slim-select-show-content-value="auto" data-slim-select-'\
        'show-search-value="true" data-slim-select-search-placeholder-value="Buscar" data-'\
        'slim-select-add-to-body-value="false" data-slim-select-select-all-text-value="Select'\
        ' all" data-slim-select-deselect-all-text-value="Deselect all"><select data-slim-'\
        'select-target="select" class="select" name="movie[status]" id="movie_status">'\
        "<option value=\"0\">draft</option>\n<option value=\"1\">done</option></select></div>"\
        '</div></div>'
      )
    end
  end

  describe '#slim_select_field' do
    it 'renders an input' do
      expect(builder.slim_select_field(:status, Movie.statuses.to_a)).to include(
        '<div class="control "><div id="status_select_div" class="slim-select" '\
        'data-controller="slim-select" data-slim-select-close-on-select-value="true" '\
        'data-slim-select-allow-deselect-option-value="false" data-slim-select-add-items'\
        '-value="false" data-slim-select-show-content-value="auto" data-slim-select-show'\
        '-search-value="true" data-slim-select-search-placeholder-value="Buscar" data-slim'\
        '-select-add-to-body-value="false" data-slim-select-select-all-text-value="Select '\
        'all" data-slim-select-deselect-all-text-value="Deselect all"><select data-slim-'\
        'select-target="select" class="select" name="movie[status]" id="movie_status">'\
        "<option value=\"0\">draft</option>\n<option value=\"1\">done</option></select></div>"\
        '</div>'
      )
    end
  end
end
