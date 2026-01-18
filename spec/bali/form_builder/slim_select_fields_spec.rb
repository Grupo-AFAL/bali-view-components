# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#slim_select_group' do
    let(:slim_select_group) { builder.slim_select_group(:status, Movie.statuses.to_a) }

    it 'renders a label and input within a wrapper' do
      expect(slim_select_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a label' do
      expect(slim_select_group).to have_css 'legend.fieldset-legend', text: 'Status'
    end

    it 'renders a div with a slim-select-controller' do
      expect(slim_select_group).to have_css 'div[data-controller="slim-select"]'
    end

    it 'renders a select' do
      expect(slim_select_group).to have_css(
        'select#movie_status[name="movie[status]"][data-slim-select-target="select"]'
      )

      Movie.statuses.each do |name, value|
        expect(slim_select_group).to have_css "option[value=\"#{value}\"]", text: name
      end
    end
  end

  describe '#slim_select_field' do
    let(:slim_select_field) { builder.slim_select_field(:status, Movie.statuses.to_a) }

    it 'renders a div with control class' do
      expect(slim_select_field).to have_css 'div.control'
    end

    it 'renders a div with a slim-select-controller' do
      expect(slim_select_field).to have_css 'div[data-controller="slim-select"]'
    end

    it 'renders a select' do
      expect(slim_select_field).to have_css(
        'select#movie_status[name="movie[status]"][data-slim-select-target="select"]'
      )

      Movie.statuses.each do |name, value|
        expect(slim_select_field).to have_css "option[value=\"#{value}\"]", text: name
      end
    end

    it 'applies DaisyUI select classes' do
      expect(slim_select_field).to have_css 'select.select.select-bordered'
    end

    it 'applies the slim-select wrapper class' do
      expect(slim_select_field).to have_css 'div.slim-select'
    end

    describe 'select_all option' do
      let(:slim_select_field) do
        builder.slim_select_field(:status, Movie.statuses.to_a, select_all: true)
      end

      it 'renders select all button' do
        expect(slim_select_field).to have_css 'a.btn.btn-sm[data-action="slim-select#selectAll"]'
      end

      it 'renders deselect all button with hidden class' do
        selector = 'a.btn.btn-sm.hidden[data-action="slim-select#deselectAll"]'
        expect(slim_select_field).to have_css selector
      end

      it 'sets data targets on buttons' do
        expect(slim_select_field).to have_css 'a[data-slim-select-target="selectAllButton"]'
        expect(slim_select_field).to have_css 'a[data-slim-select-target="deselectAllButton"]'
      end

      it 'uses i18n for button text' do
        I18n.with_locale(:en) do
          select_all_text = I18n.t('bali.form_builder.slim_select.select_all')
          deselect_all_text = I18n.t('bali.form_builder.slim_select.deselect_all')
          expect(slim_select_field).to have_text select_all_text
          expect(slim_select_field).to have_text deselect_all_text
        end
      end
    end

    describe 'custom classes' do
      it 'appends custom class to select' do
        field = builder.slim_select_field(:status, Movie.statuses.to_a, {},
                                          { class: 'custom-class' })
        expect(field).to have_css 'select.select.select-bordered.custom-class'
      end

      it 'applies select_class to wrapper' do
        field = builder.slim_select_field(:status, Movie.statuses.to_a, {},
                                          { select_class: 'wrapper-class' })
        expect(field).to have_css 'div.slim-select.wrapper-class'
      end
    end

    describe 'multiple select' do
      let(:slim_select_field) do
        builder.slim_select_field(:status, Movie.statuses.to_a, {}, { multiple: true })
      end

      it 'renders a multiple select' do
        expect(slim_select_field).to have_css 'select[multiple="multiple"]'
      end
    end

    describe 'stimulus data values' do
      it 'sets close_on_select value' do
        field = builder.slim_select_field(:status, Movie.statuses.to_a, close_on_select: false)
        expect(field).to have_css 'div[data-slim-select-close-on-select-value="false"]'
      end

      it 'sets allow_deselect_option value' do
        field = builder.slim_select_field(:status, Movie.statuses.to_a, allow_deselect_option: true)
        expect(field).to have_css 'div[data-slim-select-allow-deselect-option-value="true"]'
      end

      it 'sets placeholder value' do
        field = builder.slim_select_field(:status, Movie.statuses.to_a, {},
                                          { placeholder: 'Choose one' })
        expect(field).to have_css 'div[data-slim-select-placeholder-value="Choose one"]'
      end

      it 'sets add_items value' do
        field = builder.slim_select_field(:status, Movie.statuses.to_a, add_items: true)
        expect(field).to have_css 'div[data-slim-select-add-items-value="true"]'
      end

      it 'sets show_search value' do
        field = builder.slim_select_field(:status, Movie.statuses.to_a, show_search: false)
        expect(field).to have_css 'div[data-slim-select-show-search-value="false"]'
      end

      it 'sets custom search_placeholder' do
        field = builder.slim_select_field(:status, Movie.statuses.to_a,
                                          search_placeholder: 'Find...')
        expect(field).to have_css 'div[data-slim-select-search-placeholder-value="Find..."]'
      end

      it 'sets add_to_body value' do
        field = builder.slim_select_field(:status, Movie.statuses.to_a, add_to_body: true)
        expect(field).to have_css 'div[data-slim-select-add-to-body-value="true"]'
      end
    end

    describe 'ajax options' do
      let(:slim_select_field) do
        builder.slim_select_field(:status, Movie.statuses.to_a,
                                  ajax_url: '/api/search',
                                  ajax_param_name: 'query',
                                  ajax_value_name: 'id',
                                  ajax_text_name: 'name',
                                  ajax_placeholder: 'Loading...')
      end

      it 'sets ajax_url value' do
        expect(slim_select_field).to have_css 'div[data-slim-select-ajax-url-value="/api/search"]'
      end

      it 'sets ajax_param_name value' do
        expect(slim_select_field).to have_css 'div[data-slim-select-ajax-param-name-value="query"]'
      end

      it 'sets ajax_value_name value' do
        expect(slim_select_field).to have_css 'div[data-slim-select-ajax-value-name-value="id"]'
      end

      it 'sets ajax_text_name value' do
        expect(slim_select_field).to have_css 'div[data-slim-select-ajax-text-name-value="name"]'
      end

      it 'sets ajax_placeholder value' do
        selector = 'div[data-slim-select-ajax-placeholder-value="Loading..."]'
        expect(slim_select_field).to have_css selector
      end
    end

    describe 'after_change_fetch options' do
      let(:slim_select_field) do
        builder.slim_select_field(:status, Movie.statuses.to_a,
                                  after_change_fetch_url: '/api/update',
                                  after_change_fetch_method: 'PATCH')
      end

      it 'sets after_change_fetch_url value' do
        selector = 'div[data-slim-select-after-change-fetch-url-value="/api/update"]'
        expect(slim_select_field).to have_css selector
      end

      it 'sets after_change_fetch_method value' do
        selector = 'div[data-slim-select-after-change-fetch-method-value="PATCH"]'
        expect(slim_select_field).to have_css selector
      end
    end

    describe 'constants' do
      it 'defines WRAPPER_CLASS' do
        expect(Bali::FormBuilder::SlimSelectFields::WRAPPER_CLASS).to eq 'slim-select'
      end

      it 'defines SELECT_CLASS' do
        expect(Bali::FormBuilder::SlimSelectFields::SELECT_CLASS).to eq 'select select-bordered'
      end

      it 'defines BUTTON_CLASS' do
        expect(Bali::FormBuilder::SlimSelectFields::BUTTON_CLASS).to eq 'btn btn-sm'
      end

      it 'defines DEFAULT_OPTIONS as frozen' do
        expect(Bali::FormBuilder::SlimSelectFields::DEFAULT_OPTIONS).to be_frozen
      end
    end
  end
end
