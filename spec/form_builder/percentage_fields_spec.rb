# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#percentage_field_group' do
    it 'renders an input' do
      expect(builder.percentage_field_group(:budget)).to include(
        '<div id="field-budget" class="field-group-wrapper-component field ">'\
        '<label class="label " for="movie_budget">'\
        'Budget</label><div class="field has-addons"><div class="control "><input '\
        'placeholder="0" step="0.01" pattern="^(\\d+|\\d{1,3}(,\\d{3})*)(\\.\\d+)?$" '\
        'class="input " type="text" name="movie[budget]" id="movie_budget" /></div><div '\
        'class="control"><span class="button is-static">%</span></div></div></div>'
      )
    end
  end
end
