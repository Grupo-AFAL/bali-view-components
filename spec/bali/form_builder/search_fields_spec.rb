# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#search_field_group' do
    subject(:search_field_group) { builder.search_field_group(:name) }

    it 'renders a fieldset wrapper' do
      expect(search_field_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a legend label' do
      expect(search_field_group).to have_css 'legend.fieldset-legend', text: 'Name'
    end

    it 'renders a text input with correct attributes' do
      expect(search_field_group).to have_css(
        'input#movie_name[type="text"][name="movie[name]"]'
      )
    end

    it 'applies DaisyUI input classes' do
      expect(search_field_group).to have_css 'input.input.input-bordered'
    end

    it 'renders default placeholder from i18n' do
      expect(search_field_group).to have_css 'input[placeholder="Search..."]'
    end

    it 'renders within a join container for addon' do
      expect(search_field_group).to have_css 'div.join'
    end

    it 'applies join-item class to input' do
      expect(search_field_group).to have_css 'input.input.join-item'
    end

    it 'renders a submit button addon' do
      expect(search_field_group).to have_css 'button[type="submit"]'
    end

    it 'renders search icon in the button' do
      expect(search_field_group).to have_css 'button span.icon-component'
    end

    it 'applies default button classes' do
      expect(search_field_group).to have_css 'button.btn.btn-info'
    end

    context 'with custom placeholder' do
      subject(:search_field_group) do
        builder.search_field_group(:name, placeholder: 'Find movies...')
      end

      it 'uses custom placeholder' do
        expect(search_field_group).to have_css 'input[placeholder="Find movies..."]'
      end
    end

    context 'with custom addon_class' do
      subject(:search_field_group) do
        builder.search_field_group(:name, addon_class: 'btn btn-primary')
      end

      it 'applies custom button classes' do
        expect(search_field_group).to have_css 'button.btn.btn-primary'
      end

      it 'does not apply default btn-info class' do
        expect(search_field_group).not_to have_css 'button.btn-info'
      end
    end

    context 'with validation errors' do
      before do
        resource.errors.add(:name, 'is required')
      end

      it 'applies error class to input' do
        expect(search_field_group).to have_css 'input.input.input-error'
      end

      it 'displays error message' do
        expect(search_field_group).to have_css 'p.text-error', text: 'Name is required'
      end
    end

    context 'with custom class' do
      subject(:search_field_group) { builder.search_field_group(:name, class: 'custom-search') }

      it 'includes custom class with DaisyUI classes' do
        expect(search_field_group).to have_css 'input.input.input-bordered.custom-search'
      end
    end

    context 'with data attributes' do
      subject(:search_field_group) do
        builder.search_field_group(:name, data: { testid: 'search-input' })
      end

      it 'passes through data attributes' do
        expect(search_field_group).to have_css 'input.input[data-testid="search-input"]'
      end
    end

    context 'with required attribute' do
      subject(:search_field_group) { builder.search_field_group(:name, required: true) }

      it 'renders required input' do
        expect(search_field_group).to have_css 'input[required]'
      end
    end

    context 'with disabled attribute' do
      subject(:search_field_group) { builder.search_field_group(:name, disabled: true) }

      it 'renders disabled input' do
        expect(search_field_group).to have_css 'input[disabled]'
      end
    end
  end

  describe 'DEFAULT_BUTTON_CLASSES constant' do
    it 'is defined' do
      expect(Bali::FormBuilder::SearchFields::DEFAULT_BUTTON_CLASSES).to eq 'btn btn-info'
    end

    it 'is frozen' do
      expect(Bali::FormBuilder::SearchFields::DEFAULT_BUTTON_CLASSES).to be_frozen
    end
  end
end
