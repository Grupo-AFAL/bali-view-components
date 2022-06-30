# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#time_zone_select_group' do
    let(:time_zone_select_group) { builder.time_zone_select_group(:release_date) }
   
    it 'renders a label' do
      expect(time_zone_select_group).to have_css 'label[for="movie_release_date"]', text: 'Release date'
    end

    it 'renders a select tag' do
      expect(time_zone_select_group).to have_css 'select[name="movie[release_date]"]'
    end
  end

  describe '#time_zone_select' do
    let(:time_zone_select) { builder.time_zone_select(:release_date) }

    it 'renders a div with control class' do
      expect(time_zone_select).to have_css 'div.control'
    end

    it 'renders a select tag' do
      expect(time_zone_select).to have_css 'select[name="movie[release_date]"]'
    end
  end
end
