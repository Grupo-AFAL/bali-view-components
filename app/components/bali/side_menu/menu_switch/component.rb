# frozen_string_literal: true

module Bali
  module SideMenu
    module MenuSwitch
      class Component < ApplicationViewComponent
        # Public for the Switcher template that lists the options.
        attr_reader :href, :title, :http_method, :params, :badge

        # @param method [Symbol] `:get` (default) renders a link; any other verb renders
        #   a form (`button_to`), for an option that changes server state
        # @param params [Hash] Hidden fields of that form
        # @param badge [String, nil] Short text at the end of the option in the panel
        def initialize(title:, href:, icon:, subtitle: nil, active: false, authorized: true,
                       method: :get, params: {}, badge: nil)
          @title = title
          @subtitle = subtitle
          @icon = icon
          @href = href
          @active = active
          @authorized = authorized
          # A host forwarding an optional value can pass nil or "GET".
          @http_method = (method.presence || :get).to_s.downcase.to_sym
          @params = params
          @badge = badge
        end

        def active?
          @active && authorized?
        end

        def authorized?
          @authorized
        end

        def render?
          authorized?
        end

        private

        attr_reader :subtitle, :icon
      end
    end
  end
end
