# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#currency_field_group' do
    let(:currency_field_group) { builder.currency_field_group(:budget) }

    it 'renders a label and input within a wrapper' do
      expect(currency_field_group).to have_css 'div#field-budget.field-group-wrapper-component'
    end

    it 'renders a label' do
      expect(currency_field_group).to have_css 'label[for="movie_budget"]', text: 'Budget'
    end

    it 'renders a currency sign within a has-addons wrapper' do
      expect(currency_field_group).to have_css 'div.field.has-addons', text: '$'
    end

    it 'renders an input' do
      expect(currency_field_group).to have_css(
        'input#movie_budget[name="movie[budget]"][type="text"][step="0.01"][placeholder="0"]',
      )
    end
  end
end
