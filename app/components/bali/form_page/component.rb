# frozen_string_literal: true

module Bali
  module FormPage
    class Component < ApplicationViewComponent
      include PageComponents::Shared

      renders_one :body
      renders_one :sidebar

      MAX_WIDTHS = {
        sm: "max-w-xl",
        md: "max-w-3xl",
        lg: "max-w-5xl",
        xl: "max-w-7xl",
        full: "max-w-full"
      }.freeze

      def initialize(title:, subtitle: nil, breadcrumbs: [], back: nil, max_width: :md, card: true)
        @title = title
        @subtitle = subtitle
        @breadcrumbs = parse_breadcrumbs(breadcrumbs)
        @back = back
        @max_width = MAX_WIDTHS.fetch(max_width) do
          raise ArgumentError, "Unknown max_width: #{max_width.inspect}. Valid: #{MAX_WIDTHS.keys.join(', ')}"
        end
        @card = card
      end

      def card?
        @card
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs, :back, :max_width

      def render_body_content
        if card?
          render(Bali::Card::Component.new(style: :bordered)) { body }
        else
          body
        end
      end
    end
  end
end
