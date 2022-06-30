# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#percentage_field_group' do
    let(:percentage_field_group) { builder.percentage_field_group(:budget) }

    it 'render a label an input within a wrapper' do
      expect(percentage_field_group).to have_css 'div.field.field-group-wrapper-component'
    end

    it 'renders a label' do
      expect(percentage_field_group).to have_css 'label[for="movie_budget"]', text: 'Budget'
    end

    it 'renders a % sign' do
      expect(percentage_field_group).to have_css 'span.button.is-static', text: '%'
    end

    it 'renders an input' do
      expect(percentage_field_group).to have_css(
        'input#movie_budget[name="movie[budget]"][placeholder="0"][step="0.01"]'
      )
    end
  end
end
