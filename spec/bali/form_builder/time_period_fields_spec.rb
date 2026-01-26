# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe 'constants' do
    it 'has frozen CONTROLLER_NAME' do
      expect(Bali::FormBuilder::TimePeriodFields::CONTROLLER_NAME).to be_frozen
      expect(Bali::FormBuilder::TimePeriodFields::CONTROLLER_NAME).to eq 'time-period-field'
    end

    it 'has frozen SELECT_CLASSES with DaisyUI styling' do
      expect(Bali::FormBuilder::TimePeriodFields::SELECT_CLASSES).to be_frozen
      expect(Bali::FormBuilder::TimePeriodFields::SELECT_CLASSES)
        .to eq 'select select-bordered w-full'
    end

    it 'has frozen SELECT_WRAPPER_CLASSES' do
      expect(Bali::FormBuilder::TimePeriodFields::SELECT_WRAPPER_CLASSES).to be_frozen
      expect(Bali::FormBuilder::TimePeriodFields::SELECT_WRAPPER_CLASSES).to eq 'mb-2'
    end

    it 'has frozen DATE_FIELD_HIDDEN_CLASS' do
      expect(Bali::FormBuilder::TimePeriodFields::DATE_FIELD_HIDDEN_CLASS).to be_frozen
      expect(Bali::FormBuilder::TimePeriodFields::DATE_FIELD_HIDDEN_CLASS).to eq 'hidden'
    end
  end

  describe '#time_period_field_group' do
    let(:select_options) { [['This week', Time.zone.now.all_week]] }
    let(:result) { builder.time_period_field_group(:release_date, select_options) }

    it 'renders within a FieldGroupWrapper' do
      expect(result).to have_css 'fieldset.fieldset'
    end

    it 'renders a legend with label' do
      expect(result).to have_css 'legend.fieldset-legend', text: 'Release date'
    end

    it 'renders the time_period_field inside' do
      expect(result).to have_css 'select.select.select-bordered.w-full'
    end
  end

  describe '#time_period_field' do
    let(:select_options) do
      [['This week', Time.zone.now.all_week], ['Last week', 1.week.ago.all_week]]
    end
    let(:result) { builder.time_period_field(:release_date, select_options) }

    it 'renders a wrapper div with Stimulus controller' do
      expect(result).to have_css 'div[data-controller="time-period-field"]'
    end

    it 'renders a hidden input for the value' do
      expect(result).to have_css 'input[type="hidden"][name="movie[release_date]"]', visible: :all
    end

    it 'renders hidden input with Stimulus target' do
      expect(result).to have_css 'input[type="hidden"][data-time-period-field-target="input"]',
                                 visible: :all
    end

    it 'renders a select dropdown' do
      expect(result).to have_css 'select.select.select-bordered.w-full'
    end

    it 'renders select with proper name' do
      expect(result).to have_css 'select[name="release_date_period"]'
    end

    it 'renders select with Stimulus targets and actions' do
      expect(result).to have_css 'select[data-time-period-field-target="select"]'
      expect(result).to have_css 'select[data-action*="time-period-field#toggleDateInput"]'
      expect(result).to have_css 'select[data-action*="time-period-field#setInputValue"]'
    end

    it 'renders all provided options' do
      expect(result).to have_css 'option', text: 'This week'
      expect(result).to have_css 'option', text: 'Last week'
    end

    it 'renders select wrapper with margin class' do
      expect(result).to have_css 'div.mb-2 select'
    end

    context 'with include_blank option' do
      let(:result) do
        builder.time_period_field(:release_date, select_options, include_blank: 'Custom')
      end

      it 'adds blank option at the end' do
        expect(result).to have_css 'option', text: 'Custom'
      end

      it 'does not mutate the original select_options array' do
        original_length = select_options.length
        builder.time_period_field(:release_date, select_options, include_blank: 'Custom')
        expect(select_options.length).to eq original_length
      end
    end

    context 'with selected value matching an option' do
      let(:selected) { Time.zone.now.all_week }
      let(:result) { builder.time_period_field(:release_date, select_options, selected: selected) }

      it 'pre-selects the matching option' do
        expect(result).to have_css 'option[selected]', text: 'This week'
      end

      it 'sets the hidden input value' do
        expect(result).to have_css 'input[type="hidden"][value]', visible: :all
      end
    end

    context 'with custom date range (not in options)' do
      let(:custom_range) { 3.days.ago.all_day }
      let(:result) do
        builder.time_period_field(:release_date, select_options, selected: custom_range)
      end

      it 'does not select any dropdown option' do
        expect(result).not_to have_css 'option[selected]'
      end

      it 'shows the custom range in the date field' do
        expect(result).to have_css 'input[name="movie[release_date_date_range]"]', visible: :all
      end
    end

    context 'with object value fallback' do
      before { resource.release_date = Time.zone.now.all_week.to_s }

      it 'uses object method value when selected not provided' do
        expect(result).to have_css 'input[type="hidden"]', visible: :all
      end
    end

    describe 'date field' do
      it 'renders a date range input' do
        expect(result).to have_css 'input[name="movie[release_date_date_range]"]', visible: :all
      end

      it 'has hidden class by default' do
        expect(result).to have_css 'input.hidden', visible: :all
      end

      it 'has proper Stimulus target' do
        expect(result).to have_css 'input[data-time-period-field-target="dateInput"]', visible: :all
      end

      it 'has Stimulus action for value updates' do
        expect(result).to have_css 'input[data-action*="time-period-field#setInputValue"]',
                                   visible: :all
      end
    end

    context 'does not mutate options hash' do
      it 'does not modify the caller options' do
        options = { include_blank: 'Custom', class: 'extra' }
        original_options = options.dup
        builder.time_period_field(:release_date, select_options, **options)
        expect(options).to eq original_options
      end
    end
  end
end
