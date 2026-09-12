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
        include Bali::LocalOverlay

        # `name:` and `icon:` mean here exactly what they mean on a link item. They used to
        # mean nothing: both fell into **options and were painted as HTML attributes, so the
        # only way to label a button item was to pass a block — a difference between the two
        # kinds of item that nothing about a menu justifies.
        #
        # `modal:` / `drawer:` take the local mode only (`{ id:, local: true }`) — the same
        # contract as Bali::Button, and for the same reason: no href, nothing to fetch.
        def initialize(name: nil, icon: nil, authorized: true, modal: false, drawer: false,
                       **options)
          @name = name
          @icon = icon
          @authorized = authorized
          modal_options = validate_local_only_overlay!(:modal, modal)
          drawer_options = validate_local_only_overlay!(:drawer, drawer)
          @options = options
          @options[:type] ||= "button"
          @options[:role] ||= "menuitem"
          data = local_overlay_trigger_data(@options[:data], modal_options, drawer_options)
          @options[:data] = data if data
          @options = prepend_class_name(@options, "menu-item w-full text-left")
        end

        attr_reader :name, :icon

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
