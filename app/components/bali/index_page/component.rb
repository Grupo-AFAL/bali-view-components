# frozen_string_literal: true

module Bali
  module IndexPage
    class Component < ApplicationViewComponent
      include PageComponents::Shared

      renders_many :actions
      renders_one :body

      def initialize(title:, subtitle: nil, breadcrumbs: [])
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs.map(&:symbolize_keys)
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs
    end
  end
end
