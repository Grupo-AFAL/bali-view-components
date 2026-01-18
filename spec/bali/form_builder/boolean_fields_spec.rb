# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#boolean_field_group' do
    subject(:boolean_field_group) { builder.boolean_field_group(:indie) }

    it 'renders a fieldset wrapper' do
      expect(boolean_field_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a label with cursor-pointer class' do
      expect(boolean_field_group).to have_css 'label.label.cursor-pointer'
    end

    it 'renders checkbox with DaisyUI class' do
      expect(boolean_field_group).to have_css 'input.checkbox[type="checkbox"]'
    end

    it 'renders label text in a span' do
      expect(boolean_field_group).to have_css 'span.label-text', text: 'Indie'
    end

    it 'renders the hidden unchecked input' do
      expect(boolean_field_group).to have_css 'input[value="0"]', visible: false
    end

    it 'renders the checkbox input with correct id' do
      expect(boolean_field_group).to have_css 'input#movie_indie[value="1"]'
    end
  end

  describe '#boolean_field' do
    subject(:boolean_field) { builder.boolean_field(:indie) }

    it 'renders a label with DaisyUI classes' do
      expect(boolean_field).to have_css 'label.label.cursor-pointer'
    end

    it 'applies checkbox class to input' do
      expect(boolean_field).to have_css 'input.checkbox'
    end

    it 'renders label text in a span with label-text class' do
      expect(boolean_field).to have_css 'span.label-text', text: 'Indie'
    end

    it 'renders the hidden unchecked input' do
      expect(boolean_field).to have_css 'input[value="0"]', visible: false
    end

    it 'renders the checkbox input' do
      expect(boolean_field).to have_css 'input#movie_indie[value="1"]'
    end

    context 'with custom label' do
      subject(:boolean_field) { builder.boolean_field(:indie, label: 'Independent Film') }

      it 'uses custom label text' do
        expect(boolean_field).to have_css 'span.label-text', text: 'Independent Film'
      end
    end

    context 'with label_options' do
      subject(:boolean_field) do
        builder.boolean_field(:indie, label_options: { class: 'custom-label' })
      end

      it 'merges custom label classes with DaisyUI classes' do
        expect(boolean_field).to have_css 'label.label.cursor-pointer.custom-label'
      end
    end

    describe 'size variants' do
      described_class::BooleanFields::SIZES.each do |size, css_class|
        context "with size: :#{size}" do
          subject(:boolean_field) { builder.boolean_field(:indie, size: size) }

          it "applies #{css_class} class" do
            expect(boolean_field).to have_css "input.checkbox.#{css_class}"
          end
        end
      end
    end

    describe 'color variants' do
      described_class::BooleanFields::COLORS.each do |color, css_class|
        context "with color: :#{color}" do
          subject(:boolean_field) { builder.boolean_field(:indie, color: color) }

          it "applies #{css_class} class" do
            expect(boolean_field).to have_css "input.checkbox.#{css_class}"
          end
        end
      end
    end

    context 'with combined size and color' do
      subject(:boolean_field) { builder.boolean_field(:indie, size: :lg, color: :primary) }

      it 'applies both size and color classes' do
        expect(boolean_field).to have_css 'input.checkbox.checkbox-lg.checkbox-primary'
      end
    end

    context 'with custom class' do
      subject(:boolean_field) { builder.boolean_field(:indie, class: 'custom-checkbox') }

      it 'includes custom class with DaisyUI classes' do
        expect(boolean_field).to have_css 'input.checkbox.custom-checkbox'
      end
    end

    context 'with validation errors' do
      before do
        resource.errors.add(:indie, 'must be accepted')
      end

      it 'applies error class to checkbox' do
        expect(boolean_field).to have_css 'input.checkbox.checkbox-error'
      end

      it 'displays error message' do
        expect(boolean_field).to have_css 'p.text-error', text: 'Indie must be accepted'
      end
    end

    context 'with custom checked/unchecked values' do
      subject(:boolean_field) { builder.boolean_field(:indie, {}, 'yes', 'no') }

      it 'uses custom unchecked value' do
        expect(boolean_field).to have_css 'input[value="no"]', visible: false
      end

      it 'uses custom checked value' do
        expect(boolean_field).to have_css 'input[value="yes"]'
      end
    end

    context 'with additional HTML attributes' do
      subject(:boolean_field) { builder.boolean_field(:indie, data: { testid: 'indie-checkbox' }) }

      it 'passes through data attributes' do
        expect(boolean_field).to have_css 'input.checkbox[data-testid="indie-checkbox"]'
      end
    end
  end

  describe '#check_box_group' do
    it 'is an alias for boolean_field_group' do
      expect(builder.method(:check_box_group)).to eq(builder.method(:boolean_field_group))
    end
  end
end
