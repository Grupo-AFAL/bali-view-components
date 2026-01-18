# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#percentage_field_group' do
    let(:percentage_field_group) { builder.percentage_field_group(:budget) }

    it 'renders a label and input within a wrapper' do
      expect(percentage_field_group).to have_css 'fieldset#field-budget.fieldset'
    end

    it 'renders a label' do
      expect(percentage_field_group).to have_css 'legend.fieldset-legend', text: 'Budget'
    end

    it 'renders a % sign within a join wrapper' do
      expect(percentage_field_group).to have_css 'div.join', text: '%'
    end

    it 'renders an input' do
      expect(percentage_field_group).to have_css(
        'input#movie_budget[name="movie[budget]"][type="text"][step="0.01"][placeholder="0"]'
      )
    end

    it 'uses default % symbol' do
      expect(percentage_field_group).to have_css 'span.btn.btn-disabled.join-item', text: '%'
    end

    context 'with custom symbol' do
      let(:percentage_field_group) { builder.percentage_field_group(:budget, symbol: '‰') }

      it 'renders the custom symbol' do
        expect(percentage_field_group).to have_css 'span.btn.btn-disabled.join-item', text: '‰'
      end

      it 'does not render the default % symbol' do
        expect(percentage_field_group).to have_no_text '%'
      end
    end
  end
end
