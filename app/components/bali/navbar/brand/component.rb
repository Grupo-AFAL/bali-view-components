# frozen_string_literal: true

module Bali
  module Navbar
    module Brand
      class Component < ApplicationViewComponent
        BRAND_CLASSES = 'text-xl font-bold hover:opacity-80 transition-opacity'

        # @param name [String] Brand name/title to display
        # @param href [String] Link URL (default: '/')
        def initialize(name: nil, href: '/', **options)
          @name = name
          @href = href
          @options = prepend_class_name(options, BRAND_CLASSES)
        end

        def call
          link_to(@href, **@options) do
            content.presence || @name
          end
        end
      end
    end
  end
end
