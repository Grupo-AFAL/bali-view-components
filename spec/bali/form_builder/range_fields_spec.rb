# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#range_field_group' do
    subject(:output) { builder.range_field_group(:rating, options) }

    let(:options) { {} }

    it 'renders a fieldset wrapper' do
      expect(output).to have_css('fieldset.fieldset')
    end

    it 'renders a legend with translated label' do
      expect(output).to have_css('fieldset legend.fieldset-legend', text: 'Rating')
    end

    it 'renders a range input' do
      expect(output).to have_css('input[type="range"].range')
    end

    it 'sets default min, max, step values' do
      expect(output).to have_css('input[min="0"][max="100"][step="1"]')
    end

    it 'applies w-full class for full width' do
      expect(output).to have_css('input.range.w-full')
    end

    context 'with custom label' do
      let(:options) { { label: 'Custom Label' } }

      it 'renders custom label text' do
        expect(output).to have_css('legend', text: 'Custom Label')
      end
    end

    context 'with min, max, step options' do
      let(:options) { { min: 10, max: 500, step: 10 } }

      it 'sets custom min, max, step values' do
        expect(output).to have_css('input[min="10"][max="500"][step="10"]')
      end
    end

    describe 'size variants' do
      described_class::RangeFields::SIZES.each do |size, css_class|
        context "with size: :#{size}" do
          let(:options) { { size: size } }

          it "applies #{css_class} class" do
            expect(output).to have_css("input.range.#{css_class}")
          end
        end
      end
    end

    describe 'color variants' do
      described_class::RangeFields::COLORS.each do |color, css_class|
        context "with color: :#{color}" do
          let(:options) { { color: color } }

          it "applies #{css_class} class" do
            expect(output).to have_css("input.range.#{css_class}")
          end
        end
      end
    end

    context 'with combined size and color' do
      let(:options) { { size: :sm, color: :primary } }

      it 'applies both size and color classes' do
        expect(output).to have_css('input.range.range-sm.range-primary')
      end
    end

    context 'with show_ticks option' do
      let(:options) { { min: 0, max: 100, show_ticks: true, ticks: 3 } }

      it 'renders tick marks container' do
        expect(output).to have_css('div.flex.justify-between')
      end

      it 'renders tick labels' do
        expect(output).to have_css('div span', count: 3)
        expect(output).to have_css('span', text: '0')
        expect(output).to have_css('span', text: '50')
        expect(output).to have_css('span', text: '100')
      end
    end

    context 'with tick_labels option' do
      let(:options) { { tick_labels: %w[Low Medium High] } }

      it 'renders custom tick labels' do
        expect(output).to have_css('span', text: 'Low')
        expect(output).to have_css('span', text: 'Medium')
        expect(output).to have_css('span', text: 'High')
      end
    end

    context 'with prefix and suffix' do
      let(:options) { { min: 0, max: 100, show_ticks: true, ticks: 3, prefix: '$', suffix: 'k' } }

      it 'renders tick labels with prefix and suffix' do
        expect(output).to have_css('span', text: '$0k')
        expect(output).to have_css('span', text: '$100k')
      end
    end

    context 'with validation errors' do
      before do
        resource.errors.add(:rating, 'is invalid')
      end

      it 'applies error class to input' do
        expect(output).to have_css('input.range.range-error')
      end

      it 'renders error message' do
        expect(output).to have_css('p.text-error', text: 'Rating is invalid')
      end
    end

    context 'with custom class' do
      let(:options) { { class: 'custom-range' } }

      it 'includes custom class with DaisyUI classes' do
        expect(output).to have_css('input.range.custom-range')
      end
    end
  end

  describe '#range_field' do
    subject(:output) { builder.range_field(:rating, options) }

    let(:options) { { color: :accent } }

    it 'renders just the range input without fieldset' do
      expect(output).not_to have_css('fieldset')
      expect(output).to have_css('input[type="range"].range.range-accent')
    end
  end
end
