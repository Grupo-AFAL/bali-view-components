# frozen_string_literal: true

module Bali
  module SideMenu
    module App
      class Component < ApplicationViewComponent
        attr_reader :title, :subtitle, :icon_name, :href

        def initialize(title:, href:, icon_name:, subtitle: nil, active: false, authorized: true)
          @title = title
          @subtitle = subtitle
          @icon_name = icon_name
          @href = href
          @active = active
          @authorized = authorized
        end

        def active?
          @active && authorized?
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
