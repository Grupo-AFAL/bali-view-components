# frozen_string_literal: true

module Bali
  module SideMenu
    module MenuSwitch
      class Component < ApplicationViewComponent
        # href and title are public for use in parent component template
        attr_reader :href, :title

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

        private

        attr_reader :subtitle, :icon
      end
    end
  end
end
