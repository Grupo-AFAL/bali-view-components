# frozen_string_literal: true

module Bali
  module PageHeader
    class Preview < ApplicationViewComponentPreview
      def default(title: 'Page Header', subtitle: nil)
        render(PageHeader::Component.new(title: title, subtitle: subtitle)) do
          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end
    end
  end
end
