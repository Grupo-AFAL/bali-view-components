# frozen_string_literal: true

module Bali
  module Dropdown
    module ActionItem
      # Renders a <button> element inside a Dropdown menu.
      # Use this instead of `with_item` when the dropdown option triggers
      # a JavaScript action rather than navigating to a URL.
      #
      # This avoids the accessibility anti-pattern of <a href="#">.
      class Component < ApplicationViewComponent
        def initialize(authorized: true, **options)
          @authorized = authorized
          @options = options
          @options[:type] ||= 'button'
          @options[:role] ||= 'menuitem'
          @options = prepend_class_name(@options, 'menu-item w-full text-left')
        end

        def authorized?
          @authorized
        end

        def render?
          @authorized
        end
      end
    end
  end
end
