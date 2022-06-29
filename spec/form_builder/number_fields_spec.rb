# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#number_field_group' do
    it 'renders an input' do
      expect(builder.number_field_group(:budget)).to include(
        '<div id="field-budget" class="field-group-wrapper-component field ">'\
        '<label class="label " for="movie_budget">'\
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
end
