# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#select_group' do
    let(:select_group) { builder.select_group(:status, Movie.statuses.to_a) }

    it 'render a label an input within a wrapper' do
      expect(select_group).to have_css 'div.field.field-group-wrapper-component'
    end

    it 'renders a label' do
      expect(select_group).to have_css 'label[for="movie_status"]', text: 'Status'
    end

    it 'renders a select' do
      expect(select_group).to have_css 'select#movie_status[name="movie[status]"]'

      Movie.statuses.each do |name, value|
        expect(select_group).to have_css "option[value=\"#{value}\"]", text: name
      end
    end
  end

  describe '#select_field' do
    let(:select_field) { builder.select_field(:status, Movie.statuses.to_a) }

    it 'renders a div with control class' do
      expect(select_field).to have_css 'div.control'
    end

    it 'renders a select' do
      expect(select_field).to have_css 'select#movie_status[name="movie[status]"]'

      Movie.statuses.each do |name, value|
        expect(select_field).to have_css "option[value=\"#{value}\"]", text: name
      end
    end
  end
end
