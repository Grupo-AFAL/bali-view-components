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

      # @param klass select [is-small, is-medium, is-large]
      # @param form_class select ['has-background-white', has-background-success, has-background-warning]
      def with_custom_classes(klass: nil, form_class: nil)
        render DeleteLink::Component.new(href: '#',
                                         class: klass,
                                         form_class: form_class)
      end
    end
  end
end
