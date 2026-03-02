# frozen_string_literal: true

module Bali
  module IndexPage
    class Component < ApplicationViewComponent
      renders_many :actions
      renders_one :body

      # @param title [String] Page title
      # @param subtitle [String] Optional subtitle
      # @param breadcrumbs [Array<Hash>] Array of { name:, href:, icon_name: }
      def initialize(title:, subtitle: nil, breadcrumbs: [], **options)
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs.map(&:symbolize_keys)
        @options = options
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs
    end
  end
end
