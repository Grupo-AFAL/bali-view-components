# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#date_field_group' do
    let(:date_field_group) { builder.date_field_group(:release_date) }

    it 'renders a label and input within a wrapper' do
      expect(date_field_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a label' do
      expect(date_field_group).to have_css 'legend.fieldset-legend', text: 'Release date'
    end

    it 'renders a field with datepicker controller' do
      expect(date_field_group).to have_css 'div[data-controller="datepicker"]'
    end

    it 'renders a field with datepicker locale value' do
      expect(date_field_group).to have_css 'div[data-datepicker-locale-value="en"]'
    end

    it 'renders an input' do
      expect(date_field_group).to have_css 'input#movie_release_date[name="movie[release_date]"]'
    end

    context 'with clear option' do
      let(:date_field_group) { builder.date_field_group(:release_date, clear: true) }

      it 'renders a clear button' do
        expect(date_field_group).to have_css 'button[data-action="datepicker#clear"]'
      end

      it 'clear button has aria-label' do
        expect(date_field_group).to have_css 'button[aria-label="Clear date"]'
      end

      it 'renders clear icon' do
        expect(date_field_group).to have_css 'button span.icon-component'
      end
    end

    context 'with manual mode' do
      let(:date_field_group) { builder.date_field_group(:release_date, manual: true) }

      it 'renders a join wrapper' do
        expect(date_field_group).to have_css 'div.fieldset.flatpickr.join'
      end

      it 'renders a previous date button' do
        expect(date_field_group).to have_css 'button[data-action="datepicker#previousDate"]'
      end

      it 'renders a next date button' do
        expect(date_field_group).to have_css 'button[data-action="datepicker#nextDate"]'
      end

      it 'previous button has aria-label' do
        expect(date_field_group).to have_css 'button[aria-label="Previous date"]'
      end

      it 'next button has aria-label' do
        expect(date_field_group).to have_css 'button[aria-label="Next date"]'
      end

      it 'buttons have DaisyUI classes' do
        expect(date_field_group).to have_css 'button.btn.btn-ghost.join-item', count: 2
      end
    end

    context 'with min_date option' do
      let(:date_field_group) { builder.date_field_group(:release_date, min_date: '2024-01-01') }

      it 'passes min_date to datepicker controller' do
        expect(date_field_group).to have_css 'div[data-datepicker-min-date-value="2024-01-01"]'
      end
    end

    context 'with max_date option' do
      let(:date_field_group) { builder.date_field_group(:release_date, max_date: '2024-12-31') }

      it 'passes max_date to datepicker controller' do
        expect(date_field_group).to have_css 'div[data-datepicker-max-date-value="2024-12-31"]'
      end
    end

    context 'with disable_weekends option' do
      let(:date_field_group) { builder.date_field_group(:release_date, disable_weekends: true) }

      it 'passes disable_weekends to datepicker controller' do
        expect(date_field_group).to have_css 'div[data-datepicker-disable-weekends-value="true"]'
      end
    end

    context 'with range mode' do
      let(:date_field_group) { builder.date_field_group(:release_date, mode: 'range') }

      it 'passes mode to datepicker controller' do
        expect(date_field_group).to have_css 'div[data-datepicker-mode-value="range"]'
      end
    end

    context 'with range mode and default values' do
      let(:date_field_group) do
        builder.date_field_group(:release_date, mode: 'range', value: %w[2024-01-01 2024-01-31])
      end

      it 'passes default dates to datepicker controller' do
        expect(date_field_group).to have_css 'div[data-datepicker-default-dates-value]'
      end
    end

    context 'with period option' do
      let(:date_field_group) { builder.date_field_group(:release_date, period: 'day') }

      it 'passes period to datepicker controller' do
        expect(date_field_group).to have_css 'div[data-datepicker-period-value="day"]'
      end
    end

    context 'with custom wrapper_options' do
      let(:date_field_group) do
        builder.date_field_group(:release_date, wrapper_options: { class: 'custom-wrapper' })
      end

      it 'merges custom wrapper options' do
        expect(date_field_group).to have_css 'div.custom-wrapper[data-controller="datepicker"]'
      end
    end
  end

  describe '#month_field_group' do
    let(:month_field_group) { builder.month_field_group(:release_date) }

    it 'renders a fieldset wrapper' do
      expect(month_field_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a month input' do
      expect(month_field_group).to have_css 'input[type="month"]'
    end
  end

  describe '#month_field' do
    let(:month_field) { builder.month_field(:release_date) }

    it 'renders a month input' do
      expect(month_field).to have_css 'input[type="month"]'
    end

    it 'applies DaisyUI input classes' do
      expect(month_field).to have_css 'input.input.input-bordered'
    end
  end

  describe 'constants' do
    it 'defines WRAPPER_CLASS' do
      expect(Bali::FormBuilder::SharedDateUtils::WRAPPER_CLASS).to eq 'fieldset flatpickr'
    end

    it 'defines BUTTON_CLASS' do
      expect(Bali::FormBuilder::SharedDateUtils::BUTTON_CLASS).to eq 'btn btn-ghost'
    end

    it 'defines JOIN_ITEM_CLASS' do
      expect(Bali::FormBuilder::SharedDateUtils::JOIN_ITEM_CLASS).to eq 'join-item'
    end

    it 'freezes constants' do
      expect(Bali::FormBuilder::SharedDateUtils::WRAPPER_CLASS).to be_frozen
      expect(Bali::FormBuilder::SharedDateUtils::BUTTON_CLASS).to be_frozen
    end
  end
end
