# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#radio_field_group' do
    let(:radio_field_group) { builder.radio_field_group(:status, Movie.statuses.to_a) }

    it 'render a label an input within a control' do
      expect(radio_field_group).to have_css 'div.control'
    end

    it 'renders a label and input for each option' do
      Movie.statuses.each do |name, value|
        expect(radio_field_group).to have_css "label[for=\"movie_status_#{value}\"]", text: name
        expect(radio_field_group).to have_css "input#movie_status_#{value}[value=\"#{value}\"]"
      end
    end
  end
end
