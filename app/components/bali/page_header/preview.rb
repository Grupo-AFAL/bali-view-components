# frozen_string_literal: true

module Bali
  module PageHeader
    class Preview < ApplicationViewComponentPreview
      def default
        render PageHeader::Component.new do |c|
          c.title('Title')
          c.right_panel do
            tag.a 'Right action', class: 'button is-secondary', href: '#'
          end
        end
      end
    end
  end
end
