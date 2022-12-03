# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#file_field_group' do
    let(:file_field_group) { builder.file_field_group(:cover_photo) }

    it 'renders a div with a file-input controller' do
      expect(file_field_group).to have_css(
        'div.file[data-controller="file-input"]' \
        '[data-file-input-non-selected-text-value="No file selected"]'
      )
    end

    it 'renders an input with a data-action' do
      expect(file_field_group).to have_css(
        'input#movie_cover_photo[name="movie[cover_photo]"][data-action="file-input#onChange"]'
      )
    end

    it 'renders a label' do
      expect(file_field_group).to have_css 'label.file-label', text: 'No file selected'
    end

    it 'renders an icon' do
      expect(file_field_group).to have_css 'span.icon.icon-component'
    end
  end

  describe '#file_field' do
    let(:file_field) { builder.file_field(:cover_photo) }

    it 'renders an input' do
      expect(file_field).to have_css(
        'input#movie_cover_photo[name="movie[cover_photo]"]'
      )
    end
  end
end
