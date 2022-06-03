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
end

module Bali
  module SearchInput
    class Preview < ApplicationViewComponentPreview
      FORM = DummyFilterForm.new

      def default
        render Bali::SearchInput::Component.new(form: FORM, method: :name)
      end

      def auto_submit
        render Bali::SearchInput::Component.new(form: FORM, method: :name, auto_submit: true)
      end
    end
  end
end
