# frozen_string_literal: true

module Bali
  module SideMenu
    module MenuSwitch
      class Component < ApplicationViewComponent
        attr_reader :title, :subtitle, :icon, :href

        def initialize(title:, href:, icon:, subtitle: nil, active: false, authorized: true)
          @title = title
          @subtitle = subtitle
          @icon = icon
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
          authorized?
        end
      end
    end
  end
end
