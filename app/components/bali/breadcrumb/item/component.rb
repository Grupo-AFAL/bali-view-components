# frozen_string_literal: true

module Bali
  module Breadcrumb
    module Item
      class Component < ApplicationViewComponent
        include Bali::DeprecatedIconName

        BASE_CLASSES = "inline-flex items-center gap-1"

        # @param href [String, nil] Where the crumb leads. Without it the crumb is text.
        # @param icon [String, Symbol] Icon name, drawn before the label.
        # @param icon_name [String, nil] @deprecated Removed in Bali 4.0. Use `icon:`.
        # @param active [Boolean, nil] `true` makes this crumb the current page even with an
        #   `href`; `false` never does. `nil` leaves it to the trail: its last crumb is the current
        #   page unless it has an `href`.
        def initialize(name:, href: nil, icon: nil, icon_name: nil, active: nil, **options)
          @name = name
          @href = href
          @icon = icon || deprecated_icon_name(icon_name)
          @active = active
          @options = options
        end

        # Called by `Bali::Breadcrumb::Component` on the last item of the trail.
        def last!
          @last = true
        end

        def current?
          @active.nil? ? @last && href.blank? : @active
        end

        def link?
          href.present? && !current?
        end

        private

        attr_reader :href, :name, :icon

        def item_classes
          class_names(@options[:class])
        end

        def link_classes
          class_names(BASE_CLASSES, "no-underline hover:underline")
        end

        # daisyUI gives every `li > *` of a trail `cursor: pointer` and an underline on hover.
        def text_classes
          class_names(BASE_CLASSES, "cursor-default no-underline hover:no-underline")
        end
      end
    end
  end
end
