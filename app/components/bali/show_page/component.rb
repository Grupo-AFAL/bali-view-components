# frozen_string_literal: true

module Bali
  module ShowPage
    class Component < ApplicationViewComponent
      include PageComponents::Shared

      renders_many :title_tags
      renders_many :actions
      renders_one :body
      renders_one :sidebar

      def initialize(title:, subtitle: nil, breadcrumbs: [], back: nil)
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs.map(&:symbolize_keys)
        @back = back
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs, :back
    end
  end
end
