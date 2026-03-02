# frozen_string_literal: true

module Bali
  module FormPage
    class Component < ApplicationViewComponent
      renders_one :body
      renders_one :sidebar

      def initialize(title:, subtitle: nil, breadcrumbs: [], back: nil, max_width: "max-w-3xl", card: true, **options)
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs
        @back = back
        @max_width = max_width
        @card = card
        @options = options
      end

      def card?
        @card
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs, :back, :max_width
    end
  end
end
