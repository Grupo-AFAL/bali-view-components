# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Rate::Component, type: :component do
  let(:options) { { form: movie_form_builder, method: :rating, value: 1, auto_submit: false } }
  let(:component) { Bali::Rate::Component.new(**options) }

  it 'renders rate component' do
    render_inline(component)

    expect(page).to have_css 'div.rate-component'
    expect(page).to have_css '[data-controller="rate"]'
  end

  context 'auto submit = true' do
    before { options[:auto_submit] = true }

    it 'renders button tags for each star' do
      render_inline(component)

      expect(page).to have_css 'button.star', count: 5
      expect(page).to have_css 'button[name="movie[rating]"]', count: 5
    end

    it 'renders first 3 buttons selected' do
      options[:value] = 3
      render_inline(component)

      expect(page).to have_css 'button.star .icon-component.solid', count: 3
    end
  end

  context 'auto submit = false' do
    before { options[:auto_submit] = false }

    it 'renders labels and radio inputs for each star' do
      render_inline(component)

      expect(page).to have_css 'label.radio', count: 5
      expect(page).to have_css 'input[name="movie[rating]"]', count: 5
    end

    it 'renders first 3 inputs selected' do
      options[:value] = 3
      render_inline(component)

      expect(page).to have_css 'label.radio .icon-component.solid', count: 3
    end

    it 'radio input with default data' do
      render_inline(component)

      expect(page).to have_css 'input[data-rate-target="star"]', count: 5
      expect(page).to have_css 'input[data-action="rate#submit"]', count: 5
    end

    it 'radio input with additional data' do
      options[:radio] = { data: { action: 'survey#submit' } }
      render_inline(component)

      expect(page).to have_css 'input[data-rate-target="star"]', count: 5
      expect(page).to have_css 'input[data-action="rate#submit survey#submit"]', count: 5
    end
  end
end
