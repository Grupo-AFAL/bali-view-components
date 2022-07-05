# frozen_string_literal: true

module Bali
  module DeleteLink
    class Preview < ApplicationViewComponentPreview
      # @param name [String]
      def default(name: nil)
        render DeleteLink::Component.new(name: name, href: '#')
      end
    
      # @param name [String]
      # @param disabled toggle
      def with_hovercard(name: nil, disabled: true)
        render DeleteLink::Component.new(
          name: name,
          href: '#',
          disabled: disabled,
          disabled_hover_url: '/show-content-in-hovercard')
      end
    end
  end
end
