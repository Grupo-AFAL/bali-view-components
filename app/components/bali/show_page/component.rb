# frozen_string_literal: true

module Bali
  module ShowPage
    class Component < ApplicationViewComponent
      renders_many :title_tags
      renders_many :actions
      renders_one :body
      renders_one :sidebar

      # @param title [String] Page title
      # @param subtitle [String] Optional subtitle
      # @param breadcrumbs [Array<Hash>] Array of { name:, href:, icon_name: }
      # @param back [Hash] Back button { href: }
      def initialize(title:, subtitle: nil, breadcrumbs: [], back: nil, **options)
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs.map(&:symbolize_keys)
        @back = back
        @options = options
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs, :back
    end
  end
end
