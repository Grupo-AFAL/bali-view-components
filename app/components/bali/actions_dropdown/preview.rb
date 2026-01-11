# frozen_string_literal: true

module Bali
  module ActionsDropdown
    class Preview < ApplicationViewComponentPreview
      # Default Actions Dropdown
      # ---------------
      # Dropdown menu for row-level actions with icon trigger
      def default
        render ActionsDropdown::Component.new do |c|
          c.with_item(name: 'Edit', icon_name: 'edit', href: '#')
          c.with_item(name: 'Export', icon_name: 'file-export', href: '#')
          c.with_item(name: 'Delete', icon_name: 'trash', href: '#', method: :delete)
        end
      end

      # With Custom Content
      # ---------------
      # Custom HTML content inside the dropdown
      def with_custom_content
        render ActionsDropdown::Component.new do |c|
          c.safe_join([
                        c.render(Bali::Link::Component.new(
                                   name: 'Create',
                                   icon_name: 'plus-circle',
                                   href: '#',
                                   drawer: true,
                                   class: 'menu-item'
                                 )),
                        c.render(Bali::Link::Component.new(
                                   name: 'Export',
                                   icon_name: 'file-export',
                                   href: '#',
                                   drawer: true,
                                   class: 'menu-item'
                                 ))
                      ])
        end
      end
    end
  end
end
