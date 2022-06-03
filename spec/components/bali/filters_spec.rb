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

  def result(options = {})
    @result ||= []
  end

  def query_params
    { }
  end

  def status_in
  end
end


RSpec.describe Bali::Filters::Component, type: :component do
  let(:component) do
    Bali::Filters::Component.new(form: DummyFilterForm.new, url: '#', text_field: :name)
  end

  subject { rendered_component }

  it 'renders' do
    render_inline(component)

    is_expected.to have_css 'div.search-input-component'
    is_expected.not_to have_css 'a.filters-button'
  end

  it 'renders with filters' do
    render_inline(component) do |c|
      c.attribute(
        title: 'Active',
        attribute: :status_in,
        collection_options:  [['active', :true], ['inactive', false]])
    end

    is_expected.to have_css 'div.search-input-component'
    is_expected.to have_css 'a[id="filters-button"]'
  end
end
