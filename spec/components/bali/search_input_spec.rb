# frozen_string_literal: true

require 'rails_helper'

class DummyFilterForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string

  def model_name
    @model_name ||= ActiveModel::Name.new(self, nil, 'q')
  end

  def id
    @id ||= 1
  end

  def result(_options = {})
    @result ||= []
  end

  def query_params
    {}
  end

  def status_in; end
end

RSpec.describe Bali::SearchInput::Component, type: :component do
  let(:component) do
    Bali::SearchInput::Component.new(form: DummyFilterForm.new, method: :name, **@options)
  end

  before { @options = {} }

  subject { rendered_component }

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
