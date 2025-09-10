# frozen_string_literal: true

module Bali
  module Utils
    class DummyFilterForm
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :name, :string
      attribute :name_eq, :string
      attribute :name_matches_any, :string
      attribute :age_gteq, :decimal
      attribute :age_lteq, :decimal
      attribute :age_eq, :decimal
      attribute :cookies_accepted_true, :boolean
      attribute :privacy_accepted_true, :boolean
      attribute :terms_accepted_true, :boolean
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
