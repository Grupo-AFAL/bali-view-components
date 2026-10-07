# frozen_string_literal: true

module Bali
  module Breadcrumb
    class Preview < ApplicationViewComponentPreview
      # @param show_icons toggle
      def default(show_icons: false)
        render Bali::Breadcrumb::Component.new do |c|
          c.with_item(name: 'Home', href: '/home', icon: show_icons ? 'home' : nil)
          c.with_item(name: 'Section', href: '/home/section', icon: show_icons ? 'store' : nil)
          c.with_item(name: 'Current Page', icon: show_icons ? 'camera' : nil)
        end
      end

      # Three linked levels above the current page, the trail of an admin record. Wider than a
      # 390px screen, where the current page is the part that stays in view.
      def three_levels
        render Bali::Breadcrumb::Component.new do |c|
          c.with_item(name: 'Applications', href: '/applications')
          c.with_item(name: 'Centinela', href: '/applications/centinela')
          c.with_item(name: 'Users', href: '/applications/centinela/users')
          c.with_item(name: 'Ana García López')
        end
      end
    end
  end
end
