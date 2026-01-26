# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#url_field_group' do
    subject(:url_field_group) { builder.url_field_group(:website_url) }

    it 'renders a fieldset wrapper' do
      expect(url_field_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a legend label' do
      expect(url_field_group).to have_css 'legend.fieldset-legend',
                                          text: 'Website url'
    end

    it 'renders a url input with correct attributes' do
      expect(url_field_group).to have_css(
        'input#movie_website_url[type="url"][name="movie[website_url]"]'
      )
    end

    it 'applies DaisyUI input classes' do
      expect(url_field_group).to have_css 'input.input.input-bordered'
    end
  end

  describe '#url_field' do
    subject(:url_field) { builder.url_field(:website_url) }

    it 'renders a div with control class' do
      expect(url_field).to have_css 'div.control'
    end

    it 'renders a url input with correct attributes' do
      expect(url_field).to have_css(
        'input#movie_website_url[type="url"][name="movie[website_url]"]'
      )
    end

    it 'applies DaisyUI input classes' do
      expect(url_field).to have_css 'input.input.input-bordered'
    end

    context 'with custom class' do
      subject(:url_field) { builder.url_field(:website_url, class: 'custom-input') }

      it 'includes custom class with DaisyUI classes' do
        expect(url_field).to have_css 'input.input.input-bordered.custom-input'
      end
    end

    context 'with validation errors' do
      before do
        resource.errors.add(:website_url, 'is invalid')
      end

      it 'applies error class to input' do
        expect(url_field).to have_css 'input.input.input-error'
      end

      it 'displays error message' do
        expect(url_field).to have_css 'p.text-error', text: 'Website url is invalid'
      end
    end

    context 'with help text' do
      subject(:url_field) { builder.url_field(:website_url, help: 'Enter website URL') }

      it 'displays help text' do
        expect(url_field).to have_css 'p.label-text-alt', text: 'Enter website URL'
      end
    end

    context 'with data attributes' do
      subject(:url_field) { builder.url_field(:website_url, data: { testid: 'url-input' }) }

      it 'passes through data attributes' do
        expect(url_field).to have_css 'input.input[data-testid="url-input"]'
      end
    end

    context 'with addon_left' do
      subject(:url_field) do
        builder.url_field(:website_url,
                          addon_left: builder.content_tag(:span, 'https://', class: 'btn'))
      end

      it 'renders within a join container' do
        expect(url_field).to have_css 'div.join'
      end

      it 'applies join-item class to input' do
        expect(url_field).to have_css 'input.input.join-item'
      end

      it 'renders the addon' do
        expect(url_field).to have_css 'span.btn', text: 'https://'
      end

      it 'does not wrap in control div when addons present' do
        expect(url_field).not_to have_css 'div.control'
      end
    end

    context 'with addon_right' do
      subject(:url_field) do
        builder.url_field(:website_url,
                          addon_right: builder.content_tag(:span, '.com', class: 'btn'))
      end

      it 'renders within a join container' do
        expect(url_field).to have_css 'div.join'
      end

      it 'applies join-item class to input' do
        expect(url_field).to have_css 'input.input.join-item'
      end

      it 'renders the addon' do
        expect(url_field).to have_css 'span.btn', text: '.com'
      end
    end

    context 'with placeholder' do
      subject(:url_field) { builder.url_field(:website_url, placeholder: 'https://example.com') }

      it 'renders input with placeholder' do
        expect(url_field).to have_css 'input[placeholder="https://example.com"]'
      end
    end

    context 'with required attribute' do
      subject(:url_field) { builder.url_field(:website_url, required: true) }

      it 'renders required input' do
        expect(url_field).to have_css 'input[required]'
      end
    end

    context 'with disabled attribute' do
      subject(:url_field) { builder.url_field(:website_url, disabled: true) }

      it 'renders disabled input' do
        expect(url_field).to have_css 'input[disabled]'
      end
    end
  end
end
