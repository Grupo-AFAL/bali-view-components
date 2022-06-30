# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#email_field_group' do
    let(:email_field_group) { builder.email_field_group(:contact_email) }

    it 'renders a label and input within a wrapper' do
      expect(email_field_group).to have_css 'div.field.field-group-wrapper-component'
    end

    it 'renders a label' do
      expect(email_field_group).to have_css 'label[for="movie_contact_email"]', text: 'Contact email'
    end

    it 'renders an input' do
      expect(email_field_group).to have_css(
        'input#movie_contact_email[type="email"][name="movie[contact_email]"]'
      )
    end
  end

  describe '#email_field' do
    it 'renders an input' do
        expect(builder.email_field(:contact_email)).to have_css(
          'input#movie_contact_email[type="email"][name="movie[contact_email]"]'
        )
    end
  end
end
