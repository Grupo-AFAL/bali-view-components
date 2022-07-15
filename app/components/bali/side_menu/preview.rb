module Bali
  module SideMenu
    class Preview < ApplicationViewComponentPreview
      # Simple SideMenu
      # -------------------
      # Default menu with a section name and an item
      # @param title text
      def default(title: 'Section Title')
        render(SideMenu::Component.new(current_path: '/dashboard')) do |c|
          c.list(title: title) do |list|
            list.item(name: 'Dashboard', href: '/dashboard')
            list.item(name: 'Dashboard 2', href: '/t/dashboard')
            list.item(name: 'Inventory', href: '/inventory')
            list.item(name: 'Purchasing', href: '/purchasing')
            list.item(name: 'Configuration', href: '/configuration')
          end
        end
      end

      # SideMenu with icon in the item
      # -------------------
      # This will add an icon in the item specified
      # @param title text
      def with_icon(title: 'Section title')
        render(SideMenu::Component.new(current_path: '/attachment')) do |c|
          c.list(title: title) do |list|
            list.item(name: 'Attachment', href: '/attachment', icon: 'attachment')
            list.item(name: 'Alert', href: '/alert', icon: 'alert')
            list.item(name: 'Paypal', href: '/paypal', icon: 'paypal')
          end
        end
      end

      # SideMenu with conditional
      # -------------------
      # This will add a conditional to the item specified
      # @param title text
      def authorized(title: 'Section title')
        render(SideMenu::Component.new(current_path: '/auth-1')) do |c|
          c.list(title: title) do |list|
            list.item(name: 'Authorized 1', authorized: true, href: '/auth-1')
            list.item(name: 'Authorized 2', authorized: true, href: '/auth-2')
            list.item(name: 'Not authorized 1', authorized: false, href: '/not-auth-1')
            list.item(name: 'Not authorized 2', authorized: false, href: '/not-auth-1')
          end
        end
      end

      # SideMenu with SubMenu
      # -------------------
      # This will add subitems to an item
      # @param title text
      def with_sub_item(title: 'Section title')
        render(SideMenu::Component.new(current_path: '/parent-item')) do |c|
          c.list(title: title) do |list|
            list.item(name: 'Parent Item', href: '/parent-item') do |item|
              item.item(name: 'Child Item 1', href: '/child-item-1')
              item.item(name: 'Child Item 2', href: '/child-item-2')
              item.item(name: 'Child Item 3', href: '/child-item-3')
            end
          end
        end
      end

      # SideMenu with Active Child Item
      # -------------------
      # Will display parent as active when a child item is active
      # @param title text
      def with_active_sub_item(title: 'Section title')
        render(SideMenu::Component.new(current_path: '/child-item-1')) do |c|
          c.list(title: title) do |list|
            list.item(name: 'Parent Item', href: '/parent-item') do |item|
              item.item(name: 'Child Item 1', href: '/child-item-1')
              item.item(name: 'Child Item 2', href: '/child-item-2')
              item.item(name: 'Child Item 3', href: '/child-item-3')
            end
          end
        end
      end
    end
  end
end
