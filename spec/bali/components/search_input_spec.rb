# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::SearchInput::Component, type: :component do
  let(:form) { Bali::Utils::DummyFilterForm.new }

  def render_component(**options)
    render_inline(described_class.new(form: form, field: :name, **options))
  end

  describe 'default rendering' do
    it 'renders the search input container' do
      render_component

      expect(page).to have_css('div.search-input-component')
    end

    it 'renders input with DaisyUI classes' do
      render_component

      expect(page).to have_css('input.input.input-bordered')
    end

    it 'renders submit button with search icon' do
      render_component

      expect(page).to have_css('button.btn.btn-primary.join-item')
      expect(page).to have_css('button svg')
    end

    it 'uses join layout for input and button' do
      render_component

      expect(page).to have_css('div.form-control.join')
      expect(page).to have_css('div.join-item', count: 2)
    end

    it 'generates correct input id' do
      render_component

      expect(page).to have_css('input#q_name')
    end

    it 'generates correct input name' do
      render_component

      expect(page).to have_css('input[name="q[name]"]')
    end
  end

  describe 'with auto_submit: true' do
    it 'hides the submit button' do
      render_component(auto_submit: true)

      expect(page).not_to have_css('button')
    end

    it 'removes join classes' do
      render_component(auto_submit: true)

      expect(page).to have_css('div.form-control')
      expect(page).not_to have_css('div.join')
    end

    it 'adds stimulus action for auto-submit' do
      render_component(auto_submit: true)

      expect(page).to have_css('input[data-action="submit-on-change#submit"]')
    end
  end

  describe 'placeholder' do
    it 'uses i18n default placeholder' do
      render_component

      expect(page).to have_css('input[placeholder]')
    end

    it 'allows custom placeholder' do
      render_component(placeholder: 'Find users...')

      expect(page).to have_css('input[placeholder="Find users..."]')
    end
  end

  describe 'custom classes' do
    it 'allows adding custom input classes' do
      render_component(class: 'w-64')

      expect(page).to have_css('input.input.input-bordered.w-64')
    end
  end

  describe 'submit button options' do
    it 'accepts custom submit button classes' do
      render_component(submit: { class: 'btn-lg' })

      expect(page).to have_css('button.btn.btn-primary.join-item.btn-lg')
    end

    it 'accepts data attributes on submit button' do
      render_component(submit: { data: { testid: 'search-btn' } })

      expect(page).to have_css('button[data-testid="search-btn"]')
    end
  end

  describe 'frozen constants' do
    it 'defines BASE_INPUT_CLASSES' do
      expect(described_class::BASE_INPUT_CLASSES).to eq('input input-bordered')
    end

    it 'defines BASE_BUTTON_CLASSES' do
      expect(described_class::BASE_BUTTON_CLASSES).to eq('btn btn-primary join-item')
    end

    it 'defines CONTAINER_CLASS' do
      expect(described_class::CONTAINER_CLASS).to eq('search-input-component w-full')
    end
  end
end
