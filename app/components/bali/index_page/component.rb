# frozen_string_literal: true

module Bali
  module IndexPage
    class Component < ApplicationViewComponent
      include PageComponents::Shared

      renders_many :actions
      renders_one :body

      # @param title [String] Page title
      # @param subtitle [String] Optional subtitle
      # @param breadcrumbs [Array<Hash>] Array of { name:, href:, icon_name: }
      def initialize(title:, subtitle: nil, breadcrumbs: [])
        @title = title
        @subtitle = subtitle
        @breadcrumbs = parse_breadcrumbs(breadcrumbs)
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs
    end
  end
end
