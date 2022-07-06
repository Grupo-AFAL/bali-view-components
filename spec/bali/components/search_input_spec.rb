# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bali::SearchInput::Component, type: :component do
  let(:form) { Bali::Utils::DummyFilterForm.new }
  let(:component) do
    Bali::SearchInput::Component.new(form: form, method: :name, **@options)
  end

  before { @options = {} }

  subject { page }

  it 'renders' do
    render_inline(component)

    is_expected.to have_css 'div.search-input-component'
    is_expected.to have_css 'div.search-control'
  end

  context 'auto submit search input' do
    before { @options.merge!(auto_submit: true) }

    it 'renders' do
      render_inline(component)

      is_expected.to have_css 'div.search-input-component'
      is_expected.not_to have_css 'div.search-control'
    end
  end
end
