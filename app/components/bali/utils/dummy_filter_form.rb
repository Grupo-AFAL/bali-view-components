# frozen_string_literal: true

module Bali
  module Utils
    class DummyFilterForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :name, :string
      attribute :date_gteq, :date
      attribute :date, :date_range

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
      def date_gteq; end
    end
  end
end
