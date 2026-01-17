# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#password_field_group' do
    let(:password_field_group) { builder.password_field_group(:budget) }

    it 'renders a label and input within a wrapper' do
      expect(password_field_group).to have_css 'div.form-control'
    end

    it 'renders a label' do
      expect(password_field_group).to have_css 'label[for="movie_budget"]', text: 'Budget'
    end

    it 'renders an input' do
      expect(password_field_group).to have_css(
        'input#movie_budget[type="password"][name="movie[budget]"]'
      )
    end
  end

  describe '#password_field' do
    let(:password_field) { builder.password_field(:budget) }

    it 'renders a div with control class' do
      expect(password_field).to have_css 'div.control'
    end

    it 'renders an input' do
      expect(password_field).to have_css 'input#movie_budget[type="password"][name="movie[budget]"]'
    end
  end
end
