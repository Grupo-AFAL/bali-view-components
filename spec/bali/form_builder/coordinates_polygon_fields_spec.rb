# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#coordinates_polygon_field_group' do
    let(:coordinates_polygon_field_group) do
      builder.coordinates_polygon_field_group(:available_region)
    end

    it 'renders a label and input within a field wrapper' do
      expect(coordinates_polygon_field_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a label' do
      expect(coordinates_polygon_field_group).to have_css(
        'legend.fieldset-legend', text: 'Available region'
      )
    end

    it 'renders a hidden input and a map' do
      expect(coordinates_polygon_field_group).to have_css 'div[data-controller="drawing-maps"]'
      expect(coordinates_polygon_field_group).to have_css 'div.map'
      expect(coordinates_polygon_field_group).to have_css(
        'input#movie_available_region[value="[]"]', visible: false
      )
    end

    it 'renders clear buttons with correct text' do
      expect(coordinates_polygon_field_group).to have_button I18n.t('helpers.clear_holes.text')
      expect(coordinates_polygon_field_group).to have_button I18n.t('helpers.clear.text')
    end
  end

  describe '#coordinates_polygon_field' do
    let(:coordinates_polygon_field) { builder.coordinates_polygon_field(:available_region) }

    it 'renders a hidden input and a map' do
      expect(coordinates_polygon_field).to have_css 'div[data-controller="drawing-maps"]'
      expect(coordinates_polygon_field).to have_css 'div.map'
      expect(coordinates_polygon_field).to have_css(
        'input#movie_available_region[value="[]"]', visible: false
      )
    end

    it 'applies map height class' do
      expect(coordinates_polygon_field).to have_css 'div.map.h-\[400px\]'
    end

    it 'accepts custom value option' do
      field = builder.coordinates_polygon_field(:available_region, value: [[1, 2], [3, 4]])
      expect(field).to have_css(
        'input#movie_available_region[value="[[1,2],[3,4]]"]', visible: false
      )
    end
  end
end
