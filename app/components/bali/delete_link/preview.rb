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
          disabled_hover_url: '/show-content-in-hovercard'
        )
      end

      # @param klass [Symbol] select [btn-sm, btn-md, btn-lg]
      # @param form_class [Symbol] select [bg-base-200, bg-success, bg-warning]
      def with_custom_classes(klass: nil, form_class: nil)
        render DeleteLink::Component.new(href: '#',
                                         class: klass,
                                         form_class: form_class)
      end
    end
  end
end
