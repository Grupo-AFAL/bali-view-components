# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder do
  include_context 'form builder'

  describe '#email_field_group' do
    it 'renders an input' do
      expect(builder.email_field_group(:contact_email)).to include(
        '<div id="field-contact_email" class="field-group-wrapper-component field ">'\
        '<label class="label " for="movie_contact_email">Contact email</label>'\
        '<div class="control "><input class="input " type="email" '\
        'name="movie[contact_email]" id="movie_contact_email" /></div></div>'
      )
    end
  end

  describe '#email_field' do
    it 'renders an input' do
      expect(builder.email_field(:contact_email)).to include(
        '<div class="control "><input class="input " type="email" '\
        'name="movie[contact_email]" id="movie_contact_email" /></div>'
      )
    end
  end
end
