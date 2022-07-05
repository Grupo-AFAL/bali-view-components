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

      # @param classes select [is-small, is-medium, is-large]
      # @param form_classes select ['has-background-white', has-background-success, has-background-warning]
      def with_custom_classes(classes: nil, form_classes: nil)
        render DeleteLink::Component.new(href: '#',
                                         classes: classes,
                                         form_classes: form_classes)
      end
    end
  end
end
