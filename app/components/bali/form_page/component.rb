# frozen_string_literal: true

module Bali
  module FormPage
    class Component < ApplicationViewComponent
      include PageComponents::Shared

      self.default_max_width = :md

      def initialize(card: true, **options)
        super(**options)
        @card = card
      end

      def card?
        @card
      end

      private

      # Lo ÚNICO que FormPage no comparte con ShowPage: el cuerpo va dentro de una Card.
      # El grid con la barra lateral es el mismo y vive en el concern.
      def page_body
        form = super
        return form unless card?

        render(Bali::Card::Component.new(style: :bordered)) { form }
      end
    end
  end
end
