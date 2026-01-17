# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#switch_field_group' do
    let(:switch_field_group) { builder.switch_field_group(:indie, label: 'Indie') }

    it 'renders a div with form-control class' do
      expect(switch_field_group).to have_css 'div.form-control'
    end

    it 'renders a p tag as label' do
      expect(switch_field_group).to have_css 'p', text: 'Indie'
    end

    it 'renders a form-control wrapper' do
      expect(switch_field_group).to have_css 'div.form-control'
    end

    it 'renders the inputs' do
      expect(switch_field_group).to have_css 'input[name="movie[indie]"][value="0"]', visible: false
      expect(switch_field_group).to have_css 'input[name="movie[indie]"][value="1"]'
    end

    it 'renders an empty label' do
      expect(switch_field_group).to have_css 'label'
    end
  end

  describe '#switch_field' do
    let(:switch_field) { builder.switch_field(:indie) }
    it 'renders a form-control wrapper' do
      expect(switch_field).to have_css 'div.form-control'
    end

    it 'renders the inputs' do
      expect(switch_field).to have_css 'input[name="movie[indie]"][value="0"]', visible: false
      expect(switch_field).to have_css 'input[name="movie[indie]"][value="1"]'
    end

    it 'renders an empty label' do
      expect(switch_field).to have_css 'label'
    end
  end
end
