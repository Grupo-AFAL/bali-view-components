# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

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
