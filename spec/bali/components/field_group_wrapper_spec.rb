# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FieldGroupWrapper::Component, type: :component do
  let(:helper) { TestHelper.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil) }
  let(:resource) { Movie.new }
  let(:builder) { Bali::FormBuilder.new :movie, resource, helper, {} }

  describe 'rendering' do
    it 'renders a wrapper div with form-control classes' do
      render_inline(described_class.new(builder, :name)) { 'input content' }

      expect(page).to have_css 'div#field-name.form-control.w-full'
    end

    it 'renders the block content' do
      render_inline(described_class.new(builder, :name)) { '<input type="text" />'.html_safe }

      expect(page).to have_css 'div#field-name input[type="text"]'
    end
  end

  describe 'label' do
    it 'renders a label by default' do
      render_inline(described_class.new(builder, :name)) { 'input' }

      expect(page).to have_css 'label.label', text: 'Name'
    end

    it 'accepts custom label text as a string' do
      render_inline(described_class.new(builder, :name, label: 'Custom Label')) { 'input' }

      expect(page).to have_css 'label.label', text: 'Custom Label'
    end

    it 'accepts custom label text as a hash option' do
      render_inline(described_class.new(builder, :name, label: { text: 'Hash Label' })) { 'input' }

      expect(page).to have_css 'label.label', text: 'Hash Label'
    end

    it 'hides label when label: false' do
      render_inline(described_class.new(builder, :name, label: false)) { 'input' }

      expect(page).not_to have_css 'label'
    end

    it 'hides label when label: { text: false }' do
      render_inline(described_class.new(builder, :name, label: { text: false })) { 'input' }

      expect(page).not_to have_css 'label'
    end

    it 'hides label for hidden field type' do
      render_inline(described_class.new(builder, :name, type: 'hidden')) { 'input' }

      expect(page).not_to have_css 'label'
    end
  end

  describe 'tooltip' do
    it 'renders tooltip with info icon when tooltip option provided' do
      render_inline(described_class.new(builder, :name, label: { tooltip: 'Help text' })) { 'input' }

      expect(page).to have_css '.label-text'
      expect(page).to have_text 'Name'
    end

    it 'combines custom label text with tooltip' do
      render_inline(described_class.new(builder, :name, label: { text: 'Email', tooltip: 'Required' })) { 'input' }

      expect(page).to have_text 'Email'
    end
  end

  describe 'custom classes' do
    it 'applies field_class to the wrapper' do
      render_inline(described_class.new(builder, :name, field_class: 'max-w-md')) { 'input' }

      expect(page).to have_css 'div#field-name.max-w-md'
    end

    it 'applies class option to the wrapper' do
      render_inline(described_class.new(builder, :name, class: 'my-custom-class')) { 'input' }

      expect(page).to have_css 'div#field-name.my-custom-class'
    end

    it 'applies custom label class' do
      render_inline(described_class.new(builder, :name, label: { class: 'font-bold', tooltip: 'tip' })) { 'input' }

      expect(page).to have_css 'label.label.font-bold'
    end
  end

  describe 'data attributes' do
    it 'applies field_data to the wrapper' do
      render_inline(described_class.new(builder, :name, field_data: { testid: 'wrapper' })) { 'input' }

      expect(page).to have_css 'div[data-testid="wrapper"]'
    end
  end

  describe 'constants' do
    it 'has BASE_CLASSES constant' do
      expect(described_class::BASE_CLASSES).to eq 'form-control w-full'
    end

    it 'has LABEL_CLASSES constant' do
      expect(described_class::LABEL_CLASSES).to eq 'label'
    end

    it 'has LABEL_TEXT_CLASSES constant' do
      expect(described_class::LABEL_TEXT_CLASSES).to eq 'label-text flex items-center gap-2'
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
