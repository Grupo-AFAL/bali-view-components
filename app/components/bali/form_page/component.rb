# frozen_string_literal: true

module Bali
  module FormPage
    class Component < ApplicationViewComponent
      include PageComponents::Shared

      self.default_max_width = :md

      def initialize(card: nil, **options)
        super(**options)
        @card = card
      end

      # `nil` — the default — hands the decision to the context: a page gets the Card, a
      # drawer does not, because the drawer's own panel already IS that card. Unlike `back:`
      # and the breadcrumbs, an explicit value always wins here, `card: true` inside a drawer
      # included: a Card is decoration a caller can legitimately want in either place, not a
      # way out of the page.
      def card?
        return !drawer? if @card.nil?

        @card
      end

      private

      # The ONLY thing FormPage does not share with ShowPage: the body goes inside a Card.
      # The grid with the sidebar is the same and lives in the concern.
      def page_body
        form = super
        return form unless card?

        render(Bali::Card::Component.new(style: :bordered)) { form }
      end
    end
  end
end
