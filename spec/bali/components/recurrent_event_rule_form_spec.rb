# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::RecurrentEventRuleForm::Component, type: :component do
  let(:helper) { TestHelper.new(ActionView::LookupContext.new(ActionView::PathSet.new), {}, nil) }
  let(:resource) { Movie.new }
  let(:builder) { Bali::FormBuilder.new :movie, resource, helper, {} }
  let(:options) { {} }
  let(:component) { described_class.new(form: builder, method: :rule, **options) }

  describe 'basic rendering' do
    it 'renders the component wrapper' do
      render_inline(component)

      expect(page).to have_css 'div.recurrent-event-rule-form-component'
    end

    it 'applies the recurrent-event-rule Stimulus controller' do
      render_inline(component)

      expect(page).to have_css '[data-controller="recurrent-event-rule"]'
    end

    it 'renders hidden input for storing the RRULE value' do
      render_inline(component)

      expect(page).to have_css 'input[type="hidden"][data-recurrent-event-rule-target="input"]',
                               visible: :hidden
    end

    it 'generates unique IDs for inputs' do
      render_inline(component)

      # Check that radio button IDs contain hex-based unique ID (8 chars)
      radio = page.find('input[type="radio"]', match: :first)
      expect(radio['id']).to match(/[a-f0-9]{8}_yearly/)
    end
  end

  describe 'with value' do
    let(:options) { { value: 'FREQ=MONTHLY;INTERVAL=2' } }

    it 'renders the hidden input with the provided value' do
      render_inline(component)

      expect(page).to have_css 'input[type="hidden"][value="FREQ=MONTHLY;INTERVAL=2"]',
                               visible: :hidden
    end
  end

  describe 'disabled state' do
    let(:options) { { disabled: true } }

    it 'disables the frequency select' do
      render_inline(component)

      expect(page).to have_css 'select[name="freq"][disabled]'
    end

    it 'disables the hidden input' do
      render_inline(component)

      expect(page).to have_css 'input[type="hidden"][disabled]', visible: :hidden
    end

    it 'disables the interval input' do
      render_inline(component)

      expect(page).to have_css 'input[type="number"][name="interval"][disabled]'
    end

    it 'disables the end method select' do
      render_inline(component)

      expect(page).to have_css 'select[name="end"][disabled]'
    end
  end

  describe 'skip_end_method option' do
    let(:options) { { skip_end_method: true } }

    it 'hides the end method section' do
      render_inline(component)

      expect(page).to have_css 'fieldset.hidden', text: /End|Termina/
    end
  end

  describe 'frequency_options filtering' do
    let(:options) { { frequency_options: %w[daily weekly] } }

    it 'disables frequencies not in the allowed list' do
      render_inline(component)

      # Yearly (0), Monthly (1) should be disabled
      freq_select = page.find('select[name="freq"]')
      yearly_option = freq_select.find('option[value="0"]')
      monthly_option = freq_select.find('option[value="1"]')

      expect(yearly_option['disabled']).to be_truthy
      expect(monthly_option['disabled']).to be_truthy
    end

    it 'enables frequencies in the allowed list' do
      render_inline(component)

      freq_select = page.find('select[name="freq"]')
      weekly_option = freq_select.find('option[value="2"]')
      daily_option = freq_select.find('option[value="3"]')

      expect(weekly_option['disabled']).to be_falsey
      expect(daily_option['disabled']).to be_falsey
    end
  end

  describe 'frequency select' do
    it 'renders all frequency options by default' do
      render_inline(component)

      freq_select = page.find('select[name="freq"]')
      expect(freq_select).to have_selector('option', count: 5)
    end

    it 'has correct values for frequencies' do
      render_inline(component)

      expect(page).to have_css 'select[name="freq"] option[value="0"]' # yearly
      expect(page).to have_css 'select[name="freq"] option[value="1"]' # monthly
      expect(page).to have_css 'select[name="freq"] option[value="2"]' # weekly
      expect(page).to have_css 'select[name="freq"] option[value="3"]' # daily
      expect(page).to have_css 'select[name="freq"] option[value="4"]' # hourly
    end
  end

  describe 'ending options' do
    it 'renders the end method select' do
      render_inline(component)

      expect(page).to have_css 'select[name="end"]'
    end

    it 'has never, after, and on_date options' do
      render_inline(component)

      expect(page).to have_css 'select[name="end"] option[value=""]' # never
      expect(page).to have_css 'select[name="end"] option[value="count"]' # after
      expect(page).to have_css 'select[name="end"] option[value="until"]' # on_date
    end
  end

  describe 'yearly customization section' do
    it 'renders month selector' do
      render_inline(component)

      expect(page).to have_css 'select[name="bymonth"]'
    end

    it 'renders month day selector' do
      render_inline(component)

      expect(page).to have_css 'select[name="bymonthday"]'
    end

    it 'renders bysetpos selector for "on the" option' do
      render_inline(component)

      expect(page).to have_css 'select[name="bysetpos"]'
    end

    it 'renders byweekday selector for "on the" option' do
      render_inline(component)

      expect(page).to have_css 'select[name="byweekday"]'
    end
  end

  describe 'weekly customization section' do
    it 'renders day checkboxes' do
      render_inline(component)

      # One checkbox per day of the week
      expect(page).to have_css 'input[type="checkbox"][data-rrule-attr="byweekday"]', count: 7
    end

    it 'applies peer classes for label styling' do
      render_inline(component)

      expect(page).to have_css 'input[type="checkbox"].peer.sr-only'
    end
  end

  describe 'DaisyUI classes' do
    it 'applies select-bordered to selects' do
      render_inline(component)

      expect(page).to have_css 'select.select.select-bordered[name="freq"]'
    end

    it 'applies input-bordered to number inputs' do
      render_inline(component)

      expect(page).to have_css 'input.input.input-bordered[type="number"]'
    end

    it 'applies radio class to radio buttons' do
      render_inline(component)

      expect(page).to have_css 'input[type="radio"].radio'
    end
  end

  describe 'Stimulus data attributes' do
    it 'has intervalInputContainer target' do
      render_inline(component)

      expect(page).to have_css '[data-recurrent-event-rule-target="intervalInputContainer"]'
    end

    it 'has freqCustomizationInputsContainer targets' do
      render_inline(component)

      selector = '[data-recurrent-event-rule-target="freqCustomizationInputsContainer"]'
      expect(page).to have_css selector, minimum: 4
    end

    it 'has endMethodSelect target' do
      render_inline(component)

      expect(page).to have_css '[data-recurrent-event-rule-target="endMethodSelect"]'
    end

    it 'has endCustomizationInputsContainer targets' do
      render_inline(component)

      selector = '[data-recurrent-event-rule-target="endCustomizationInputsContainer"]'
      expect(page).to have_css selector, minimum: 3
    end
  end

  describe 'options passthrough' do
    let(:options) { { class: 'custom-class' } }

    it 'merges custom classes' do
      render_inline(component)

      expect(page).to have_css 'div.recurrent-event-rule-form-component.custom-class'
    end
  end

  describe 'i18n' do
    it 'translates frequency labels' do
      render_inline(component)

      # Check that at least one translated label appears
      expect(page).to have_text(/Yearly|Anualmente/i)
    end

    it 'translates repeat label' do
      render_inline(component)

      expect(page).to have_text(/Repeat|Repetir/i)
    end

    it 'translates end label' do
      render_inline(component)

      expect(page).to have_text(/End|Termina/i)
    end
  end
end
