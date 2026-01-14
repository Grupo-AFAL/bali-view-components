# frozen_string_literal: true

module Bali
  module Breadcrumb
    class Preview < ApplicationViewComponentPreview
      def default
        render Breadcrumb::Component.new do |c|
          c.with_item(href: '/home', name: 'Home')
          c.with_item(href: '/home/section', name: 'Section')
          c.with_item(href: '/home/section/page', name: 'Page', active: true)
        end
      end

      def with_icons
        render Breadcrumb::Component.new do |c|
          c.with_item(href: '/home', name: 'Home', icon_name: 'home')
          c.with_item(href: '/home/store', name: 'Store', icon_name: 'store')
          c.with_item(href: '/home/store/product', name: 'Product', icon_name: 'camera', active: true)
        end
      end
    end
  end
end
