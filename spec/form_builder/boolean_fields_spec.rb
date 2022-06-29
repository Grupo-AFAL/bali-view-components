# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

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
end
