# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#slim_select_group' do
    let(:slim_select_group) { builder.slim_select_group(:status, Movie.statuses.to_a) }

    it 'render a label an input within a wrapper' do
      expect(slim_select_group).to have_css 'div.field.field-group-wrapper-component'
    end

    it 'renders a label' do
      expect(slim_select_group).to have_css 'label[for="movie_status"]', text: 'Status'
    end

    it 'renders a div with a slim-select-controller' do
      expect(slim_select_group).to have_css 'div[data-controller="slim-select"]'
    end

    it 'renders a select' do
      expect(slim_select_group).to have_css(
        'select#movie_status[name="movie[status]"][data-slim-select-target="select"]'
      )

      Movie.statuses.each do |name, value|
        expect(slim_select_group).to have_css "option[value=\"#{value}\"]", text: name
      end
    end
  end

  describe '#slim_select_field' do
    let(:slim_select_field) { builder.slim_select_field(:status, Movie.statuses.to_a) }

    it 'renders a div with control class' do
      expect(slim_select_field).to have_css 'div.control'
    end

    it 'renders a div with a slim-select-controller' do
      expect(slim_select_field).to have_css 'div[data-controller="slim-select"]'
    end

    it 'renders a select' do
      expect(slim_select_field).to have_css(
        'select#movie_status[name="movie[status]"][data-slim-select-target="select"]'
      )

      Movie.statuses.each do |name, value|
        expect(slim_select_field).to have_css "option[value=\"#{value}\"]", text: name
      end
    end
  end
end
