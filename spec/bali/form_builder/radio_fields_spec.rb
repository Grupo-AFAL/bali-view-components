# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#radio_field_group' do
    let(:radio_field_group) { builder.radio_field_group(:status, Movie.statuses.to_a) }

    it 'renders a label and input within a control' do
      expect(radio_field_group).to have_css 'div.control'
    end

    it 'renders a label and input for each option' do
      Movie.statuses.each_value do |value|
        expect(radio_field_group).to have_css "label[for=\"movie_status_#{value}\"]"
        expect(radio_field_group).to have_css "input#movie_status_#{value}[value=\"#{value}\"]"
      end
    end

    it 'renders radio inputs with DaisyUI radio class' do
      expect(radio_field_group).to have_css 'input.radio'
    end

    it 'renders labels with cursor-pointer class' do
      expect(radio_field_group).to have_css 'label.label.cursor-pointer'
    end

    it 'renders display text in span with label-text class' do
      expect(radio_field_group).to have_css 'span.label-text'
    end
  end

  describe '#radio_field' do
    let(:values) { [%w[One 1], %w[Two 2], %w[Three 3]] }
    let(:radio_field) { builder.radio_field(:status, values) }

    it 'renders radio inputs for each value' do
      expect(radio_field).to have_css 'input[type="radio"]', count: 3
    end

    it 'renders labels with correct for attributes' do
      expect(radio_field).to have_css 'label[for="movie_status_1"]'
      expect(radio_field).to have_css 'label[for="movie_status_2"]'
      expect(radio_field).to have_css 'label[for="movie_status_3"]'
    end

    context 'with size option' do
      let(:radio_field) { builder.radio_field(:status, values, {}, { size: :lg }) }

      it 'applies size class to radio inputs' do
        expect(radio_field).to have_css 'input.radio.radio-lg', count: 3
      end
    end

    context 'with color option' do
      let(:radio_field) { builder.radio_field(:status, values, {}, { color: :primary }) }

      it 'applies color class to radio inputs' do
        expect(radio_field).to have_css 'input.radio.radio-primary', count: 3
      end
    end

    context 'with custom label class' do
      let(:radio_field) do
        builder.radio_field(:status, values, {}, { radio_label_class: 'custom-label' })
      end

      it 'appends custom class to labels' do
        expect(radio_field).to have_css 'label.label.cursor-pointer.custom-label', count: 3
      end
    end

    context 'with custom input class' do
      let(:radio_field) { builder.radio_field(:status, values, {}, { class: 'custom-input' }) }

      it 'appends custom class to radio inputs' do
        expect(radio_field).to have_css 'input.radio.custom-input', count: 3
      end
    end

    context 'with vertical orientation (default)' do
      let(:radio_field) { builder.radio_field(:status, values) }

      it 'renders container with flex-col class' do
        expect(radio_field).to have_css 'div.flex.flex-col.gap-1'
      end
    end

    context 'with horizontal orientation' do
      let(:radio_field) { builder.radio_field(:status, values, {}, { orientation: :horizontal }) }

      it 'renders container with flex-row class' do
        expect(radio_field).to have_css 'div.flex.flex-row.flex-wrap'
      end
    end
  end

  describe 'ORIENTATIONS constant' do
    it 'includes vertical and horizontal options' do
      expect(described_class::RadioFields::ORIENTATIONS.keys).to contain_exactly(:vertical,
                                                                                 :horizontal)
    end

    it 'maps vertical to flex-col layout' do
      expect(described_class::RadioFields::ORIENTATIONS[:vertical]).to include('flex-col')
    end

    it 'maps horizontal to flex-row layout' do
      expect(described_class::RadioFields::ORIENTATIONS[:horizontal]).to include('flex-row')
    end

    it 'is frozen' do
      expect(described_class::RadioFields::ORIENTATIONS).to be_frozen
    end
  end

  describe 'SIZES constant' do
    it 'includes all DaisyUI radio sizes' do
      expect(described_class::RadioFields::SIZES.keys).to contain_exactly(:xs, :sm, :md, :lg)
    end

    it 'maps to correct DaisyUI classes' do
      expect(described_class::RadioFields::SIZES[:xs]).to eq('radio-xs')
      expect(described_class::RadioFields::SIZES[:lg]).to eq('radio-lg')
    end

    it 'is frozen' do
      expect(described_class::RadioFields::SIZES).to be_frozen
    end
  end

  describe 'COLORS constant' do
    it 'includes all DaisyUI radio colors' do
      expect(described_class::RadioFields::COLORS.keys).to contain_exactly(
        :primary, :secondary, :accent, :success, :warning, :info, :error
      )
    end

    it 'maps to correct DaisyUI classes' do
      expect(described_class::RadioFields::COLORS[:primary]).to eq('radio-primary')
      expect(described_class::RadioFields::COLORS[:error]).to eq('radio-error')
    end

    it 'is frozen' do
      expect(described_class::RadioFields::COLORS).to be_frozen
    end
  end

  describe 'class constants' do
    it 'defines RADIO_CLASS' do
      expect(described_class::RadioFields::RADIO_CLASS).to eq('radio')
    end

    it 'defines LABEL_CLASS with cursor-pointer and spacing' do
      expect(described_class::RadioFields::LABEL_CLASS)
        .to eq('label cursor-pointer justify-start gap-3')
    end

    it 'defines LABEL_TEXT_CLASS' do
      expect(described_class::RadioFields::LABEL_TEXT_CLASS).to eq('label-text')
    end

    it 'defines ERROR_CLASS' do
      expect(described_class::RadioFields::ERROR_CLASS).to eq('label-text-alt text-error')
    end

    it 'defines CONTROLLER_NAME' do
      expect(described_class::RadioFields::CONTROLLER_NAME).to eq('radio-buttons-group')
    end
  end
end
