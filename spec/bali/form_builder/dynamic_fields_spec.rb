# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe Bali::FormBuilder::DynamicFields do
    describe 'constants' do
      it 'defines HEADER_CLASS' do
        expect(described_class::HEADER_CLASS).to eq('flex justify-between items-center')
      end

      it 'defines LABEL_WRAPPER_CLASS' do
        expect(described_class::LABEL_WRAPPER_CLASS).to eq('flex items-center')
      end

      it 'defines LABEL_CLASS' do
        expect(described_class::LABEL_CLASS).to eq('label')
      end

      it 'defines BUTTON_WRAPPER_CLASS' do
        expect(described_class::BUTTON_WRAPPER_CLASS).to eq('flex items-center')
      end

      it 'defines DEFAULT_BUTTON_CLASS' do
        expect(described_class::DEFAULT_BUTTON_CLASS).to eq('btn btn-primary')
      end

      it 'defines DESTROY_FLAG_CLASS' do
        expect(described_class::DESTROY_FLAG_CLASS).to eq('destroy-flag')
      end

      it 'defines CONTROLLER_NAME' do
        expect(described_class::CONTROLLER_NAME).to eq('dynamic-fields')
      end

      it 'defines CHILD_INDEX_PLACEHOLDER' do
        expect(described_class::CHILD_INDEX_PLACEHOLDER).to eq('new_record')
      end

      it 'freezes all CSS class constants' do
        expect(described_class::HEADER_CLASS).to be_frozen
        expect(described_class::LABEL_WRAPPER_CLASS).to be_frozen
        expect(described_class::LABEL_CLASS).to be_frozen
        expect(described_class::BUTTON_WRAPPER_CLASS).to be_frozen
        expect(described_class::DEFAULT_BUTTON_CLASS).to be_frozen
        expect(described_class::DESTROY_FLAG_CLASS).to be_frozen
        expect(described_class::CONTROLLER_NAME).to be_frozen
        expect(described_class::CHILD_INDEX_PLACEHOLDER).to be_frozen
      end
    end
  end

  describe '#link_to_remove_fields' do
    let(:remove_link) { builder.link_to_remove_fields('Remove', **options) }
    let(:options) { {} }

    it 'renders a link element' do
      expect(remove_link).to have_css 'a', text: 'Remove'
    end

    it 'includes href="#" on the link' do
      expect(remove_link).to have_css 'a[href="#"]'
    end

    it 'adds Stimulus action for removing fields' do
      expect(remove_link).to have_css 'a[data-action*="dynamic-fields#removeFields"]'
    end

    it 'renders a hidden field for _destroy' do
      expect(remove_link).to have_css 'input[type="hidden"][name*="_destroy"]', visible: false
    end

    it 'applies destroy-flag class to hidden field' do
      expect(remove_link).to have_css 'input.destroy-flag', visible: false
    end

    context 'with custom class' do
      let(:options) { { class: 'btn btn-error' } }

      it 'applies custom class to link' do
        expect(remove_link).to have_css 'a.btn.btn-error'
      end
    end

    context 'with data attributes' do
      let(:options) { { data: { testid: 'remove-btn' } } }

      it 'passes through data attributes' do
        expect(remove_link).to have_css 'a[data-testid="remove-btn"]'
      end

      it 'merges action with existing data' do
        expect(remove_link).to have_css 'a[data-action*="dynamic-fields#removeFields"]'
      end
    end

    context 'with soft_delete: true' do
      # Create a resource that supports soft delete
      let(:soft_delete_resource) do
        resource = Movie.new
        resource.define_singleton_method(:_soft_delete) { nil }
        resource
      end

      let(:soft_delete_builder) do
        Bali::FormBuilder.new(:movie, soft_delete_resource, helper, {})
      end

      let(:remove_link) { soft_delete_builder.link_to_remove_fields('Remove', soft_delete: true) }

      it 'renders hidden field for _soft_delete instead of _destroy' do
        expect(remove_link).to have_css 'input[type="hidden"][name*="_soft_delete"]', visible: false
      end

      it 'does not render _destroy hidden field' do
        expect(remove_link).not_to have_css 'input[name*="_destroy"]', visible: false
      end
    end

    context 'with soft_delete: false' do
      let(:options) { { soft_delete: false } }

      it 'renders hidden field for _destroy' do
        expect(remove_link).to have_css 'input[type="hidden"][name*="_destroy"]', visible: false
      end
    end
  end

  describe '#dynamic_fields_group' do
    let(:movie_with_characters) do
      movie = Movie.new
      allow(movie).to receive(:characters).and_return([])
      movie
    end

    let(:mock_template) do
      template = helper
      allow(template).to receive(:render).and_return('')
      allow(template).to receive(:capture) do |&block|
        block&.call
      end
      template
    end

    let(:builder_with_characters) do
      Bali::FormBuilder.new(:movie, movie_with_characters, mock_template, {})
    end

    context 'with custom block' do
      let(:dynamic_group) do
        builder_with_characters.dynamic_fields_group(:characters) do
          '<custom>content</custom>'.html_safe
        end
      end

      it 'renders the Stimulus controller wrapper' do
        expect(dynamic_group).to have_css '[data-controller="dynamic-fields"]'
      end

      it 'sets size value to 0 for empty association' do
        expect(dynamic_group).to have_css '[data-dynamic-fields-size-value="0"]'
      end

      it 'sets fields selector value' do
        selector = '[data-dynamic-fields-fields-selector-value=".character-fields"]'
        expect(dynamic_group).to have_css selector
      end

      it 'renders the container with target attribute' do
        expect(dynamic_group).to have_css '[data-dynamic-fields-target="container"]'
      end

      it 'renders the container div with id based on model and association' do
        expect(dynamic_group).to have_css 'div[id="movie_character_container"]'
      end
    end

    context 'data attributes' do
      let(:dynamic_group) do
        builder_with_characters.dynamic_fields_group(:characters) { '' }
      end

      it 'includes controller name' do
        expect(dynamic_group).to include('data-controller="dynamic-fields"')
      end

      it 'includes size value' do
        expect(dynamic_group).to include('data-dynamic-fields-size-value="0"')
      end

      it 'includes fields selector' do
        selector_attr = 'data-dynamic-fields-fields-selector-value=".character-fields"'
        expect(dynamic_group).to include(selector_attr)
      end
    end
  end

  describe '#link_to_add_fields' do
    let(:movie_with_characters) do
      movie = Movie.new
      allow(movie).to receive(:characters).and_return([])
      allow(movie.class).to receive(:reflect_on_association).with(:characters).and_return(
        double(klass: Character)
      )
      movie
    end

    let(:mock_template) do
      template = helper
      field_html = '<div class="character-fields">field</div>'.html_safe
      allow(template).to receive(:render).and_return(field_html)
      template
    end

    let(:builder_with_characters) do
      Bali::FormBuilder.new(:movie, movie_with_characters, mock_template, {})
    end

    let(:add_link) do
      builder_with_characters.link_to_add_fields(
        'Add Character', :characters, **options
      )
    end
    let(:options) { {} }

    it 'renders a link with the provided text' do
      expect(add_link).to have_css 'a', text: 'Add Character'
    end

    it 'includes href="#" on the link' do
      expect(add_link).to have_css 'a[href="#"]'
    end

    it 'adds Stimulus action for adding fields' do
      expect(add_link).to have_css 'a[data-action*="dynamic-fields#addFields"]'
    end

    it 'adds Stimulus target for button' do
      expect(add_link).to have_css 'a[data-dynamic-fields-target="button"]'
    end

    it 'renders a template element with Stimulus target' do
      # Template elements are not visible, so check the raw HTML output
      expect(add_link.to_s).to include('<template')
      expect(add_link.to_s).to include('data-dynamic-fields-target="template"')
    end

    context 'with wrapper_class option' do
      let(:options) { { wrapper_class: 'mt-4' } }

      it 'applies wrapper class to containing div' do
        expect(add_link).to have_css 'div.mt-4'
      end
    end

    context 'with custom class' do
      let(:options) { { class: 'btn btn-secondary' } }

      it 'applies custom class to link' do
        expect(add_link).to have_css 'a.btn.btn-secondary'
      end
    end
  end
end
