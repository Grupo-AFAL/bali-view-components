# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FieldGroupWrapper::Component, type: :component do
  let(:helper) { TestHelper.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil) }
  let(:resource) { Movie.new }
  let(:builder) { Bali::FormBuilder.new :movie, resource, helper, {} }

  describe 'rendering' do
    it 'renders a fieldset wrapper with DaisyUI fieldset classes' do
      render_inline(described_class.new(builder, :name)) { 'input content' }

      expect(page).to have_css 'fieldset#field-name.fieldset.w-full'
    end

    it 'renders the block content' do
      render_inline(described_class.new(builder, :name)) { '<input type="text" />'.html_safe }

      expect(page).to have_css 'fieldset#field-name input[type="text"]'
    end
  end

  describe 'legend (label)' do
    it 'renders a legend by default' do
      render_inline(described_class.new(builder, :name)) { 'input' }

      expect(page).to have_css 'legend.fieldset-legend', text: 'Name'
    end

    it 'accepts custom label text as a string' do
      render_inline(described_class.new(builder, :name, label: 'Custom Label')) { 'input' }

      expect(page).to have_css 'legend.fieldset-legend', text: 'Custom Label'
    end

    it 'accepts custom label text as a hash option' do
      render_inline(described_class.new(builder, :name, label: { text: 'Hash Label' })) { 'input' }

      expect(page).to have_css 'legend.fieldset-legend', text: 'Hash Label'
    end

    it 'hides legend when label: false' do
      render_inline(described_class.new(builder, :name, label: false)) { 'input' }

      expect(page).not_to have_css 'legend'
    end

    it 'hides legend when label: { text: false }' do
      render_inline(described_class.new(builder, :name, label: { text: false })) { 'input' }

      expect(page).not_to have_css 'legend'
    end

    it 'hides legend for hidden field type' do
      render_inline(described_class.new(builder, :name, type: 'hidden')) { 'input' }

      expect(page).not_to have_css 'legend'
    end
  end

  describe 'tooltip' do
    it 'renders tooltip with info icon when tooltip option provided' do
      render_inline(described_class.new(builder, :name, label: { tooltip: 'Help text' })) do
        'input'
      end

      expect(page).to have_css 'legend.fieldset-legend'
      expect(page).to have_text 'Name'
    end

    it 'combines custom label text with tooltip' do
      render_inline(described_class.new(builder, :name,
                                        label: { text: 'Email', tooltip: 'Required' })) do
        'input'
      end

      expect(page).to have_text 'Email'
    end
  end

  describe 'custom classes' do
    it 'applies field_class to the wrapper' do
      render_inline(described_class.new(builder, :name, field_class: 'max-w-md')) { 'input' }

      expect(page).to have_css 'fieldset#field-name.max-w-md'
    end

    it 'applies class option to the wrapper' do
      render_inline(described_class.new(builder, :name, class: 'my-custom-class')) { 'input' }

      expect(page).to have_css 'fieldset#field-name.my-custom-class'
    end

    it 'applies custom label class' do
      render_inline(described_class.new(builder, :name,
                                        label: { class: 'font-bold', tooltip: 'tip' })) do
        'input'
      end

      expect(page).to have_css 'legend.fieldset-legend.font-bold'
    end
  end

  describe 'data attributes' do
    it 'applies field_data to the wrapper' do
      render_inline(described_class.new(builder, :name, field_data: { testid: 'wrapper' })) do
        'input'
      end

      expect(page).to have_css 'fieldset[data-testid="wrapper"]'
    end
  end

  describe 'constants' do
    it 'has BASE_CLASSES constant for DaisyUI fieldset pattern' do
      expect(described_class::BASE_CLASSES).to eq 'fieldset w-full'
    end

    it 'has LEGEND_CLASSES constant' do
      expect(described_class::LEGEND_CLASSES).to eq 'fieldset-legend'
    end

    it 'has LEGEND_TEXT_CLASSES constant' do
      expect(described_class::LEGEND_TEXT_CLASSES).to eq 'flex items-center gap-2'
    end
  end

  describe 'options isolation' do
    it 'does not mutate the passed options hash' do
      options = { label: 'Test', field_class: 'custom', field_data: { foo: 'bar' } }
      original_keys = options.keys.dup

      render_inline(described_class.new(builder, :name, options)) { 'input' }

      expect(options.keys).to eq original_keys
    end
  end
end
