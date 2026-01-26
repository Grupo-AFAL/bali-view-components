# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::FormBuilder, type: :form_builder do
  include_context 'form builder'

  describe 'SubmitFields constants' do
    it 'defines BUTTON_BASE_CLASS' do
      expect(described_class::SubmitFields::BUTTON_BASE_CLASS).to eq('btn')
    end

    it 'defines WRAPPER_CLASS' do
      expect(described_class::SubmitFields::WRAPPER_CLASS).to eq('inline')
    end

    it 'defines SUBMIT_ACTIONS_CLASS' do
      expect(described_class::SubmitFields::SUBMIT_ACTIONS_CLASS).to eq(
        'submit-actions flex items-center justify-end gap-2'
      )
    end

    it 'defines frozen VARIANTS hash' do
      expect(described_class::SubmitFields::VARIANTS).to be_frozen
      expect(described_class::SubmitFields::VARIANTS).to include(
        primary: 'btn-primary',
        secondary: 'btn-secondary',
        success: 'btn-success',
        error: 'btn-error'
      )
    end

    it 'defines frozen SIZES hash' do
      expect(described_class::SubmitFields::SIZES).to be_frozen
      expect(described_class::SubmitFields::SIZES).to include(
        xs: 'btn-xs',
        sm: 'btn-sm',
        lg: 'btn-lg'
      )
    end
  end

  describe '#submit' do
    let(:submit) { builder.submit('Save') }

    it 'renders an inline div wrapper' do
      expect(submit).to have_css 'div.inline'
    end

    it 'renders a submit button with default primary variant' do
      expect(submit).to have_css 'button[type="submit"].btn.btn-primary', text: 'Save'
    end

    context 'with variant option' do
      it 'applies secondary variant' do
        result = builder.submit('Cancel', variant: :secondary)
        expect(result).to have_css 'button.btn.btn-secondary'
      end

      it 'applies success variant' do
        result = builder.submit('Complete', variant: :success)
        expect(result).to have_css 'button.btn.btn-success'
      end

      it 'applies error variant' do
        result = builder.submit('Delete', variant: :error)
        expect(result).to have_css 'button.btn.btn-error'
      end

      it 'applies ghost variant' do
        result = builder.submit('Skip', variant: :ghost)
        expect(result).to have_css 'button.btn.btn-ghost'
      end
    end

    context 'with size option' do
      it 'applies xs size' do
        result = builder.submit('Save', size: :xs)
        expect(result).to have_css 'button.btn.btn-xs'
      end

      it 'applies sm size' do
        result = builder.submit('Save', size: :sm)
        expect(result).to have_css 'button.btn.btn-sm'
      end

      it 'applies lg size' do
        result = builder.submit('Save', size: :lg)
        expect(result).to have_css 'button.btn.btn-lg'
      end

      it 'applies no size class for md (default)' do
        result = builder.submit('Save', size: :md)
        expect(result).to have_css 'button.btn'
        expect(result).not_to have_css 'button.btn-md'
      end
    end

    context 'with custom wrapper_class' do
      let(:submit) { builder.submit('Save', wrapper_class: 'custom-wrapper') }

      it 'uses the custom wrapper class' do
        expect(submit).to have_css 'div.custom-wrapper'
        expect(submit).not_to have_css 'div.inline'
      end
    end

    context 'with custom class' do
      let(:submit) { builder.submit('Save', class: 'extra-class') }

      it 'appends the custom class' do
        expect(submit).to have_css 'button.btn.btn-primary.extra-class'
      end
    end

    context 'with modal option' do
      let(:submit) { builder.submit('Save', modal: true) }

      it 'includes modal#submit stimulus action' do
        expect(submit).to have_css 'button[data-action*="modal#submit"]'
      end
    end

    context 'with drawer option' do
      let(:submit) { builder.submit('Save', drawer: true) }

      it 'includes drawer#submit stimulus action' do
        expect(submit).to have_css 'button[data-action*="drawer#submit"]'
      end
    end

    context 'when Bali.native_app is true' do
      before { allow(Bali).to receive(:native_app).and_return(true) }

      it 'does not add modal stimulus action' do
        result = builder.submit('Save', modal: true)
        expect(result).not_to have_css '[data-action*="modal#submit"]'
      end

      it 'does not add drawer stimulus action' do
        result = builder.submit('Save', drawer: true)
        expect(result).not_to have_css '[data-action*="drawer#submit"]'
      end
    end

    context 'with data attributes' do
      let(:submit) { builder.submit('Save', data: { testid: 'submit-btn' }) }

      it 'passes through data attributes' do
        expect(submit).to have_css 'button[data-testid="submit-btn"]'
      end
    end
  end

  describe '#submit_actions' do
    context 'with cancel_path and cancel_options' do
      let(:submit_actions) do
        builder.submit_actions('Save', cancel_path: '/', cancel_options: { label: 'Back' })
      end

      it 'renders buttons within a wrapper' do
        expect(submit_actions).to have_css 'div.submit-actions.flex.items-center.justify-end.gap-2'
      end

      it 'renders a cancel button' do
        expect(submit_actions).to have_css 'a.btn.btn-secondary[href="/"]', text: 'Back'
      end

      it 'renders a submit button' do
        expect(submit_actions).to have_css 'button[type="submit"].btn.btn-primary', text: 'Save'
      end

      it 'renders cancel before submit' do
        # Cancel link should come before submit button in the DOM
        doc = Nokogiri::HTML(submit_actions)
        wrapper = doc.at_css('div.submit-actions')
        children = wrapper.children.select(&:element?)
        expect(children.first.name).to eq('div')
        expect(children.first.at_css('a')).to be_present
        expect(children.last.at_css('button')).to be_present
      end
    end

    context 'without cancel path' do
      let(:submit_actions) { builder.submit_actions('Save') }

      it 'renders only the submit button' do
        expect(submit_actions).to have_css 'button[type="submit"]', text: 'Save'
        expect(submit_actions).not_to have_css 'a'
      end
    end

    context 'with modal option and cancel_path' do
      let(:submit_actions) do
        builder.submit_actions('Save', cancel_path: '/', modal: true)
      end

      it 'adds modal#close action to cancel button' do
        expect(submit_actions).to have_css 'a[data-action*="modal#close"]'
      end

      it 'adds modal#submit action to submit button' do
        expect(submit_actions).to have_css 'button[data-action*="modal#submit"]'
      end
    end

    context 'with drawer option and cancel_path' do
      let(:submit_actions) do
        builder.submit_actions('Save', cancel_path: '/', drawer: true)
      end

      it 'adds drawer#close action to cancel button' do
        expect(submit_actions).to have_css 'a[data-action*="drawer#close"]'
      end

      it 'adds drawer#submit action to submit button' do
        expect(submit_actions).to have_css 'button[data-action*="drawer#submit"]'
      end
    end

    context 'with modal option only (no cancel_path)' do
      let(:submit_actions) { builder.submit_actions('Save', modal: true) }

      it 'renders cancel button element with modal#close when modal is true' do
        # When no path is provided, uses button instead of link
        expect(submit_actions).to have_css 'button[data-action*="modal#close"]'
      end

      it 'uses default Cancel label' do
        expect(submit_actions).to have_css 'button', text: 'Cancel'
      end

      it 'renders button with type="button" to prevent form submission' do
        expect(submit_actions).to have_css 'button[type="button"]', text: 'Cancel'
      end
    end

    context 'with custom field_class' do
      let(:submit_actions) do
        builder.submit_actions('Save', field_class: 'custom-actions')
      end

      it 'uses the custom field class' do
        expect(submit_actions).to have_css 'div.custom-actions'
        expect(submit_actions).not_to have_css 'div.submit-actions'
      end
    end

    context 'with field_id' do
      let(:submit_actions) do
        builder.submit_actions('Save', field_id: 'form-actions')
      end

      it 'sets the id on the wrapper' do
        expect(submit_actions).to have_css 'div#form-actions'
      end
    end

    context 'with field_data' do
      let(:submit_actions) do
        builder.submit_actions('Save', field_data: { controller: 'form-actions' })
      end

      it 'sets data attributes on the wrapper' do
        expect(submit_actions).to have_css 'div[data-controller="form-actions"]'
      end
    end

    context 'when Bali.native_app is true and modal is true' do
      before { allow(Bali).to receive(:native_app).and_return(true) }

      let(:submit_actions) do
        builder.submit_actions('Save', cancel_path: '/', modal: true)
      end

      it 'does not render cancel button' do
        expect(submit_actions).not_to have_css 'a'
      end

      it 'renders only submit button' do
        expect(submit_actions).to have_css 'button[type="submit"]', text: 'Save'
      end
    end

    context 'with variant option' do
      let(:submit_actions) do
        builder.submit_actions('Delete', variant: :error)
      end

      it 'applies variant to submit button' do
        expect(submit_actions).to have_css 'button.btn.btn-error'
      end
    end
  end
end
