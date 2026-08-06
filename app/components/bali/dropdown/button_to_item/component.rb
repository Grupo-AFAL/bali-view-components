# frozen_string_literal: true

module Bali
  module Dropdown
    module ButtonToItem
      # The menu item for a state transition: POST/PATCH/PUT as a real `button_to`, so the
      # action survives without JavaScript and a control that mutates state is a button,
      # not a link. `Dropdown#with_item` builds it for `method: :post | :patch | :put` —
      # the same routing that hands `:delete` to DeleteLink — and passes
      # `form_class: "contents"`, which takes the `<form>` out of the box tree so the
      # button is the menu item daisyUI paints (#829).
      class Component < ApplicationViewComponent
        def initialize(href:, method:, name: nil, icon: nil, authorized: true, **options)
          @href = href
          @method = method
          @name = name
          @icon = icon
          @authorized = authorized
          @form_class = options.delete(:form_class)
          @form_options = options.delete(:form) || {}
          @options = options
        end

        attr_reader :href, :method, :name, :icon, :form_class, :form_options

        # The same base the other plain items carry (Link's `plain:` and DeleteLink's),
        # so the three kinds of item line up their icon and label identically.
        def button_classes
          class_names("flex items-center gap-2", @options[:class])
        end

        def button_options
          @options.except(:class)
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
