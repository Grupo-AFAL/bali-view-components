# frozen_string_literal: true

module Bali
  module Utils
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

      def result
        @result ||= []
      end

      def query_params
        {}
      end

      def status_in; end
    end
  end
end
