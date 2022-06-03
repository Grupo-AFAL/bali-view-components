# frozen_string_literal: true

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

module Bali
  module Filters
    class Preview < ApplicationViewComponentPreview
      FORM = DummyFilterForm.new

      def default
        render Bali::Filters::Component.new(form: FORM, url: '#', text_field: :name)
      end

      def with_filter_attributes
        render Bali::Filters::Component.new(form: FORM, url: '#', text_field: :name) do |c|
          c.attribute(
            title: 'Active',
            attribute: :status_in,
            collection_options:  [['active', :true], ['inactive', false]])
        end
      end
    end
  end
end
