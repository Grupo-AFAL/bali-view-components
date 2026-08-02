# frozen_string_literal: true

module Bali
  module Breadcrumb
    class Preview < ApplicationViewComponentPreview
      # @param show_icons toggle
      def default(show_icons: false)
        render Breadcrumb::Component.new do |c|
          c.with_item(name: 'Home', href: '/home', icon: show_icons ? 'home' : nil)
          c.with_item(name: 'Section', href: '/home/section', icon: show_icons ? 'store' : nil)
          c.with_item(name: 'Current Page', icon: show_icons ? 'camera' : nil)
        end
      end
    end
  end
end
