# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#file_field_group' do
    let(:file_field_group) { builder.file_field_group(:cover_photo) }

    it 'renders a div with a file-input controller' do
      expect(file_field_group).to have_css(
        'div.flex[data-controller="file-input"]' \
        '[data-file-input-non-selected-text-value="No file selected"]'
      )
    end

    it 'renders an input with a data-action' do
      expect(file_field_group).to have_css(
        'input#movie_cover_photo[name="movie[cover_photo]"][data-action="file-input#onChange"]'
      )
    end

    it 'renders a label with cursor-pointer class' do
      expect(file_field_group).to have_css 'label.cursor-pointer', text: 'No file selected'
    end

    it 'renders an icon' do
      expect(file_field_group).to have_css 'span.icon-component'
    end

    it 'renders with file-input class on the input' do
      expect(file_field_group).to have_css 'input.file-input'
    end

    it 'renders the CTA button with proper classes' do
      expect(file_field_group).to have_css 'span.btn.btn-ghost.btn-sm.gap-2'
    end

    it 'renders the filename display with truncate class' do
      expect(file_field_group).to have_css 'span.truncate'
    end
  end

  describe '#file_field' do
    let(:file_field) { builder.file_field(:cover_photo) }

    it 'renders an input' do
      expect(file_field).to have_css(
        'input#movie_cover_photo[name="movie[cover_photo]"]'
      )
    end

    it 'renders with file-input class' do
      expect(file_field).to have_css 'input.file-input'
    end
  end

  describe 'customization options' do
    it 'accepts custom choose_file_text' do
      html = builder.file_field(:cover_photo, choose_file_text: 'Upload Image')
      expect(html).to have_css 'span', text: 'Upload Image'
    end

    it 'accepts custom non_selected_text' do
      html = builder.file_field(:cover_photo, non_selected_text: 'No image')
      expect(html).to have_css 'span', text: 'No image'
      expect(html).to have_css '[data-file-input-non-selected-text-value="No image"]'
    end

    it 'hides label when choose_file_text is false' do
      html = builder.file_field(:cover_photo, choose_file_text: false)
      expect(html).to have_css 'span.btn.btn-ghost span.icon-component'
      expect(html).not_to have_css 'span.btn.btn-ghost span:not(.icon-component)'
    end

    it 'accepts custom icon' do
      html = builder.file_field(:cover_photo, icon: 'camera')
      expect(html).to have_css 'span.icon-component'
    end

    it 'accepts file_class for wrapper styling' do
      html = builder.file_field(:cover_photo, file_class: 'custom-wrapper')
      expect(html).to have_css 'div.custom-wrapper'
    end

    it 'preserves wrapper base classes when file_class is provided' do
      html = builder.file_field(:cover_photo, file_class: 'custom-wrapper')
      expect(html).to have_css 'div.flex.custom-wrapper'
    end
  end

  describe 'multiple file selection' do
    it 'sets multiple attribute on input' do
      html = builder.file_field(:cover_photo, multiple: true)
      expect(html).to have_css 'input[multiple]'
    end

    it 'passes multiple value to Stimulus controller' do
      html = builder.file_field(:cover_photo, multiple: true)
      expect(html).to have_css '[data-file-input-multiple-value="true"]'
    end

    it 'sets multiple value to false by default' do
      html = builder.file_field(:cover_photo)
      expect(html).to have_css '[data-file-input-multiple-value="false"]'
    end
  end

  describe 'HTML attributes passthrough' do
    it 'accepts accept attribute for file types' do
      html = builder.file_field(:cover_photo, accept: '.jpg,.png')
      expect(html).to have_css 'input[accept=".jpg,.png"]'
    end

    it 'accepts required attribute' do
      html = builder.file_field(:cover_photo, required: true)
      expect(html).to have_css 'input[required]'
    end

    it 'accepts custom data attributes' do
      html = builder.file_field(:cover_photo, data: { testid: 'file-upload' })
      expect(html).to have_css 'input[data-testid="file-upload"]'
    end

    it 'merges custom classes with file-input class' do
      html = builder.file_field(:cover_photo, class: 'custom-input')
      expect(html).to have_css 'input.file-input.custom-input'
    end
  end

  describe 'i18n' do
    it 'uses translated choose_file_text by default' do
      I18n.with_locale(:en) do
        html = builder.file_field(:cover_photo)
        expect(html).to have_css 'span', text: 'Choose file'
      end
    end

    it 'uses translated non_selected_text by default' do
      I18n.with_locale(:en) do
        html = builder.file_field(:cover_photo)
        expect(html).to have_css 'span', text: 'No file selected'
      end
    end

    it 'supports Spanish locale' do
      I18n.with_locale(:es) do
        html = builder.file_field(:cover_photo)
        expect(html).to have_css 'span', text: 'Seleccionar archivo'
        expect(html).to have_css 'span', text: 'Ningún archivo seleccionado'
      end
    end
  end

  describe 'constants' do
    it 'has INPUT_CLASS constant' do
      expect(described_class::FileFields::INPUT_CLASS).to eq('file-input')
    end

    it 'has WRAPPER_CLASS constant' do
      expect(described_class::FileFields::WRAPPER_CLASS).to eq('flex items-center gap-2')
    end

    it 'has FILENAME_CLASS constant' do
      expect(described_class::FileFields::FILENAME_CLASS).to eq('truncate text-base-content/70')
    end

    it 'has CTA_CLASS constant' do
      expect(described_class::FileFields::CTA_CLASS).to eq('btn btn-ghost btn-sm gap-2')
    end

    it 'has LABEL_CLASS constant' do
      expect(described_class::FileFields::LABEL_CLASS).to eq('cursor-pointer')
    end

    it 'has DEFAULT_ICON constant' do
      expect(described_class::FileFields::DEFAULT_ICON).to eq('upload')
    end
  end
end
