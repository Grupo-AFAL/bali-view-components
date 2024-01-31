# frozen_string_literal: true

module Bali
  module Breadcrumb
    class Preview < ApplicationViewComponentPreview
      # Breadcrumbs
      # -----------
      # A simple breadcrumb component to improve your navigation experience
      #
      # @param alignment select [left, centered, right]
      # @param separator select [slash, arrow, bullet, dot, succeeds]
      # @param size select [regular, small, medium, large]
      def default(alignment: :left, separator: :slash, size: :regular)
        render Breadcrumb::Component.new(class: classes(alignment, separator, size)) do |c|
          c.with_item(href: '/home', name: 'Home')
          c.with_item(href: '/home/section', name: 'Section')
          c.with_item(href: '/home/section/page', name: 'Page', active: true)
        end
      end

      # Breadcrumbs with icons
      # ---------------------
      #
      # @param alignment select [left, centered, right]
      # @param separator select [arrow, bullet, dot, succeeds]
      # @param size select [small, medium, large]
      def with_icons(alignment: :left, separator: :slash, size: :regular)
        render Breadcrumb::Component.new(class: classes(alignment, separator, size)) do |c|
          c.with_item(href: '/home', name: 'Home', icon_name: 'home')
          c.with_item(href: '/home/store', name: 'Store', icon_name: 'store')
          c.with_item(href: '/home/store/snowflake', name: 'Snowflake',
                 icon_name: 'snowflake', active: true)
        end
      end

      private

      def classes(alignment, separator, size)
        "is-#{alignment} has-#{separator}-separator is-#{size}"
      end
    end
  end
end
