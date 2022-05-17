# frozen_string_literal: true

module Bali
  module PageHeader
    class Preview < ApplicationViewComponentPreview
      def default
        render PageHeader::Component.new do |c|
          c.title('Title')

          tag.a 'Right action', class: 'button is-secondary', href: '#'
        end
      end
    end
  end
end
