# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#time_zone_select_group' do
    let(:time_zone_select_group) { builder.time_zone_select_group(:release_date) }

    it 'renders a label' do
      expect(time_zone_select_group).to have_css 'legend.fieldset-legend',
                                                 text: 'Release date'
    end

    it 'renders a select tag' do
      expect(time_zone_select_group).to have_css 'select[name="movie[release_date]"]'
    end

    it 'renders DaisyUI select classes' do
      expect(time_zone_select_group).to have_css 'select.select.select-bordered.w-full'
    end
  end

  describe '#time_zone_select' do
    subject(:time_zone_select) { builder.time_zone_select(:release_date) }

    it 'renders a control wrapper' do
      expect(time_zone_select).to have_css 'div.control'
    end

    it 'renders a select tag' do
      expect(time_zone_select).to have_css 'select[name="movie[release_date]"]'
    end

    it 'renders DaisyUI base classes' do
      expect(time_zone_select).to have_css 'select.select.select-bordered.w-full'
    end

    context 'with priority zones' do
      subject(:time_zone_select) do
        builder.time_zone_select(:release_date, ActiveSupport::TimeZone.us_zones)
      end

      it 'renders with priority zones at the top' do
        # Priority zones appear before the separator
        expect(time_zone_select).to have_css 'select option', minimum: 10
      end
    end

    context 'with custom class' do
      subject(:time_zone_select) do
        builder.time_zone_select(:release_date, nil, {}, { class: 'custom' })
      end

      it 'appends custom class to base classes' do
        expect(time_zone_select).to have_css 'select.select.select-bordered.w-full.custom'
      end
    end

    context 'with help text' do
      subject(:time_zone_select) do
        builder.time_zone_select(:release_date, nil, {}, { help: 'Select your time zone' })
      end

      it 'renders help text' do
        expect(time_zone_select).to have_css 'p.label-text-alt', text: 'Select your time zone'
      end
    end

    context 'with errors' do
      subject(:time_zone_select) { builder.time_zone_select(:release_date) }

      before { resource.errors.add(:release_date, 'is invalid') }

      it 'renders input-error class' do
        expect(time_zone_select).to have_css 'select.input-error'
      end

      it 'renders error message' do
        expect(time_zone_select).to have_css 'p.text-error', text: 'Release date is invalid'
      end
    end

    describe 'does not mutate input hashes' do
      it 'preserves the original html_options hash' do
        html_options = { class: 'my-class', help: 'Help text' }
        original_keys = html_options.keys.dup

        builder.time_zone_select(:release_date, nil, {}, html_options)

        expect(html_options.keys).to eq(original_keys)
      end
    end
  end
end
