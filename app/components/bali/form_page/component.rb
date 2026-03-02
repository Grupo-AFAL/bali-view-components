# frozen_string_literal: true

module Bali
  module FormPage
    class Component < ApplicationViewComponent
      renders_one :body
      renders_one :sidebar

      MAX_WIDTHS = {
        sm: "max-w-xl",
        md: "max-w-3xl",
        lg: "max-w-5xl",
        xl: "max-w-7xl",
        full: "max-w-full"
      }.freeze

      def initialize(title:, subtitle: nil, breadcrumbs: [], back: nil, max_width: :md, card: true, **options)
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs.map(&:symbolize_keys)
        @back = back
        @max_width = MAX_WIDTHS.fetch(max_width, max_width.to_s)
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
