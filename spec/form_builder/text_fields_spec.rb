# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#text_field_group' do
    it 'renders an input' do
      expect(builder.text_field_group(:name)).to include(
        '<div id="field-name" class="field-group-wrapper-component field ">'\
        '<label class="label " for="movie_name">Name</label>'\
        '<div class="control "><input class="input " type="text" name="movie[name]" '\
        'id="movie_name" /></div></div>'
      )
    end
  end

  describe '#text_field' do
    it 'renders an input' do
      expect(builder.text_field(:name)).to include(
        '<div class="control ">'\
        '<input class="input " type="text" name="movie[name]" id="movie_name" />'\
        '</div>'
      )
    end
  end
end
