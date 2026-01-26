# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe '#email_field_group' do
    subject(:email_field_group) { builder.email_field_group(:contact_email) }

    it 'renders a fieldset wrapper' do
      expect(email_field_group).to have_css 'fieldset.fieldset'
    end

    it 'renders a legend label' do
      expect(email_field_group).to have_css 'legend.fieldset-legend',
                                            text: 'Contact email'
    end

    it 'renders an email input with correct attributes' do
      expect(email_field_group).to have_css(
        'input#movie_contact_email[type="email"][name="movie[contact_email]"]'
      )
    end

    it 'applies DaisyUI input classes' do
      expect(email_field_group).to have_css 'input.input.input-bordered'
    end
  end

  describe '#email_field' do
    subject(:email_field) { builder.email_field(:contact_email) }

    it 'renders a div with control class' do
      expect(email_field).to have_css 'div.control'
    end

    it 'renders an email input with correct attributes' do
      expect(email_field).to have_css(
        'input#movie_contact_email[type="email"][name="movie[contact_email]"]'
      )
    end

    it 'applies DaisyUI input classes' do
      expect(email_field).to have_css 'input.input.input-bordered'
    end

    context 'with custom class' do
      subject(:email_field) { builder.email_field(:contact_email, class: 'custom-input') }

      it 'includes custom class with DaisyUI classes' do
        expect(email_field).to have_css 'input.input.input-bordered.custom-input'
      end
    end

    context 'with validation errors' do
      before do
        resource.errors.add(:contact_email, 'is invalid')
      end

      it 'applies error class to input' do
        expect(email_field).to have_css 'input.input.input-error'
      end

      it 'displays error message' do
        expect(email_field).to have_css 'p.text-error', text: 'Contact email is invalid'
      end
    end

    context 'with help text' do
      subject(:email_field) { builder.email_field(:contact_email, help: 'Enter your email') }

      it 'displays help text' do
        expect(email_field).to have_css 'p.label-text-alt', text: 'Enter your email'
      end
    end

    context 'with data attributes' do
      subject(:email_field) { builder.email_field(:contact_email, data: { testid: 'email-input' }) }

      it 'passes through data attributes' do
        expect(email_field).to have_css 'input.input[data-testid="email-input"]'
      end
    end

    context 'with addon_left' do
      subject(:email_field) do
        builder.email_field(:contact_email,
                            addon_left: builder.content_tag(:span, '@', class: 'btn'))
      end

      it 'renders within a join container' do
        expect(email_field).to have_css 'div.join'
      end

      it 'applies join-item class to input' do
        expect(email_field).to have_css 'input.input.join-item'
      end

      it 'renders the addon' do
        expect(email_field).to have_css 'span.btn', text: '@'
      end
    end

    context 'with addon_right' do
      subject(:email_field) do
        builder.email_field(:contact_email,
                            addon_right: builder.content_tag(:span, '.com', class: 'btn'))
      end

      it 'renders within a join container' do
        expect(email_field).to have_css 'div.join'
      end

      it 'applies join-item class to input' do
        expect(email_field).to have_css 'input.input.join-item'
      end

      it 'renders the addon' do
        expect(email_field).to have_css 'span.btn', text: '.com'
      end
    end

    context 'with placeholder' do
      subject(:email_field) { builder.email_field(:contact_email, placeholder: 'you@example.com') }

      it 'renders input with placeholder' do
        expect(email_field).to have_css 'input[placeholder="you@example.com"]'
      end
    end

    context 'with required attribute' do
      subject(:email_field) { builder.email_field(:contact_email, required: true) }

      it 'renders required input' do
        expect(email_field).to have_css 'input[required]'
      end
    end

    context 'with disabled attribute' do
      subject(:email_field) { builder.email_field(:contact_email, disabled: true) }

      it 'renders disabled input' do
        expect(email_field).to have_css 'input[disabled]'
      end
    end
  end
end
