# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::Form::Errors::Component, type: :component do
  let(:model) { FormRecord.new }

  describe 'rendering' do
    context 'when model has no errors' do
      it 'renders nothing' do
        render_inline(described_class.new(model: model))

        expect(page.text).to be_empty
      end
    end

    context 'when model has errors' do
      before do
        model.errors.add(:name, "can't be blank")
        model.errors.add(:email, 'is invalid')
      end

      it 'renders the error messages' do
        render_inline(described_class.new(model: model))

        expect(page).to have_css('.alert.alert-error')
        expect(page).to have_text("Name can't be blank")
        expect(page).to have_text('Email is invalid')
      end

      it 'renders errors in a list' do
        render_inline(described_class.new(model: model))

        expect(page).to have_css('ul.list-disc li', count: 2)
      end

      it 'includes margin-bottom by default' do
        render_inline(described_class.new(model: model))

        expect(page).to have_css('.alert.mb-4')
      end
    end

    context 'with title' do
      before do
        model.errors.add(:name, "can't be blank")
      end

      it 'renders the title' do
        render_inline(described_class.new(model: model, title: 'Please fix these errors:'))

        expect(page).to have_text('Please fix these errors:')
      end
    end

    context 'with custom classes' do
      before do
        model.errors.add(:name, "can't be blank")
      end

      it 'applies custom classes' do
        render_inline(described_class.new(model: model, class: 'my-custom-class'))

        expect(page).to have_css('.alert.my-custom-class')
      end
    end
  end
end
