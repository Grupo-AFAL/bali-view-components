# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#switch_field_group' do
    subject(:switch_field_group) { builder.switch_field_group(:indie) }

    it 'renders a fieldset wrapper' do
      expect(switch_field_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a label with cursor-pointer class' do
      expect(switch_field_group).to have_css 'label.label.cursor-pointer'
    end

    it 'renders toggle with DaisyUI class' do
      expect(switch_field_group).to have_css 'input.toggle[type="checkbox"]'
    end

    it 'renders label text in a span' do
      expect(switch_field_group).to have_css 'span.label-text', text: 'Indie'
    end

    it 'renders the hidden unchecked input' do
      expect(switch_field_group).to have_css 'input[value="0"]', visible: false
    end

    it 'renders the toggle input with correct id' do
      expect(switch_field_group).to have_css 'input#movie_indie[value="1"]'
    end
  end

  describe '#switch_field' do
    subject(:switch_field) { builder.switch_field(:indie) }

    it 'renders a label with DaisyUI classes' do
      expect(switch_field).to have_css 'label.label.cursor-pointer'
    end

    it 'applies toggle class to input' do
      expect(switch_field).to have_css 'input.toggle'
    end

    it 'renders label text in a span with label-text class' do
      expect(switch_field).to have_css 'span.label-text', text: 'Indie'
    end

    it 'renders the hidden unchecked input' do
      expect(switch_field).to have_css 'input[value="0"]', visible: false
    end

    it 'renders the toggle input' do
      expect(switch_field).to have_css 'input#movie_indie[value="1"]'
    end

    context 'with custom label' do
      subject(:switch_field) { builder.switch_field(:indie, label: 'Independent Film') }

      it 'uses custom label text' do
        expect(switch_field).to have_css 'span.label-text', text: 'Independent Film'
      end
    end

    context 'with label_options' do
      subject(:switch_field) do
        builder.switch_field(:indie, label_options: { class: 'custom-label' })
      end

      it 'merges custom label classes with DaisyUI classes' do
        expect(switch_field).to have_css 'label.label.cursor-pointer.custom-label'
      end
    end

    describe 'size variants' do
      described_class::SwitchFields::SIZES.each do |size, css_class|
        context "with size: :#{size}" do
          subject(:switch_field) { builder.switch_field(:indie, size: size) }

          it "applies #{css_class} class" do
            expect(switch_field).to have_css "input.toggle.#{css_class}"
          end
        end
      end
    end

    describe 'color variants' do
      described_class::SwitchFields::COLORS.each do |color, css_class|
        context "with color: :#{color}" do
          subject(:switch_field) { builder.switch_field(:indie, color: color) }

          it "applies #{css_class} class" do
            expect(switch_field).to have_css "input.toggle.#{css_class}"
          end
        end
      end
    end

    context 'with combined size and color' do
      subject(:switch_field) { builder.switch_field(:indie, size: :lg, color: :primary) }

      it 'applies both size and color classes' do
        expect(switch_field).to have_css 'input.toggle.toggle-lg.toggle-primary'
      end
    end

    context 'with custom class' do
      subject(:switch_field) { builder.switch_field(:indie, class: 'custom-toggle') }

      it 'includes custom class with DaisyUI classes' do
        expect(switch_field).to have_css 'input.toggle.custom-toggle'
      end
    end

    context 'with validation errors' do
      before do
        resource.errors.add(:indie, 'must be accepted')
      end

      it 'applies error class to toggle' do
        expect(switch_field).to have_css 'input.toggle.toggle-error'
      end

      it 'displays error message' do
        expect(switch_field).to have_css 'p.text-error', text: 'Indie must be accepted'
      end
    end

    context 'with custom checked/unchecked values' do
      subject(:switch_field) { builder.switch_field(:indie, {}, 'yes', 'no') }

      it 'uses custom unchecked value' do
        expect(switch_field).to have_css 'input[value="no"]', visible: false
      end

      it 'uses custom checked value' do
        expect(switch_field).to have_css 'input[value="yes"]'
      end
    end

    context 'with additional HTML attributes' do
      subject(:switch_field) { builder.switch_field(:indie, data: { testid: 'indie-toggle' }) }

      it 'passes through data attributes' do
        expect(switch_field).to have_css 'input.toggle[data-testid="indie-toggle"]'
      end
    end
  end
end
