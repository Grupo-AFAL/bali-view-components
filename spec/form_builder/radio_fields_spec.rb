# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

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
end
