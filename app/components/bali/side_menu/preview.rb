module Bali
  module SideMenu
    class Preview < ApplicationViewComponentPreview
      # Simple SideMenu
      # -------------------
      # Default menu with a section name and an item
      # @param title text
      def default(title: 'Section Title')
        render(SideMenu::Component.new(current_path: '/dashboard')) do |c|
          c.with_list(title: title) do |list|
            list.with_item(name: 'Dashboard', href: '/dashboard')
            list.with_item(name: 'Dashboard 2', href: '/t/dashboard')
            list.with_item(name: 'Inventory', href: '/inventory')
            list.with_item(name: 'Purchasing', href: '/purchasing')
            list.with_item(name: 'Configuration', href: '/configuration')
          end
        end
      end

      # With multiple apps
      # -------------------
      # Default menu with a section name and an item
      # @param title text
      def with_menu_switcher(title: 'Section Title')
        render(SideMenu::Component.new(
          current_path: '/inv/counts', collapsable: true, data: { controller: 'side-menu' }
        )) do |c|
          c.with_menu_switch(
            title: 'BoH', subtitle: 'Back of house', href: '/boh/dashboard',
            active: true, icon: 'cutlery-alt'
          )
          c.with_menu_switch(
            title: 'Logistics', subtitle: 'Logistics team', href: '/logistics/dashboard',
            icon: :truck
          )
          c.with_menu_switch(
            title: 'Accounting', subtitle: 'Acct team', href: '/acct/dashboard',
            icon: 'wallet-alt'
          )

          c.with_list do |list|
            list.with_item(name: 'Dashboard', href: '/boh/dashboard', icon: :dashboard)
            list.with_item(name: 'Recipes', href: '/boh/recipes', icon: 'recipe-book')
            list.with_item(name: 'Production', icon: :week) do |item|
              item.with_item(name: 'Plans', href: '/production/plans', icon: :ticket)
            end
          end

          c.with_list(title: title) do |list|
            list.with_item(name: 'Inventory', icon: :table) do |item|
              item.with_item(name: 'Counts', href: '/inv/counts', icon: :report)
              item.with_item(name: 'Waste', href: '/inv/waste', icon: :trash)
              item.with_item(name: 'Storage locations', href: '/inv/storage_locations', icon: :pin)
            end
            list.with_item(name: 'Procurement', icon: 'money-bill-wave') do |item|
              item.with_item(
                name: 'Purchase orders', href: '/procurement/purchase_orders', icon: 'sticky-note'
              )
              item.with_item(
                name: 'Shopping list', href: '/procurement/shopping_list', icon: 'shopping-cart'
              )
            end
            list.with_item(name: 'Configuration', href: '/configuration', icon: :cog)
          end
        end
      end

      # SideMenu with icon in the item
      # -------------------
      # This will add an icon in the item specified
      # @param title text
      def with_icon(title: 'Section title')
        render(SideMenu::Component.new(current_path: '/attachment')) do |c|
          c.with_list(title: title) do |list|
            list.with_item(name: 'Attachment', href: '/attachment', icon: 'attachment')
            list.with_item(name: 'Alert', href: '/alert', icon: 'alert')
            list.with_item(name: 'Paypal', href: '/paypal', icon: 'paypal')
          end
        end
      end

      # SideMenu with conditional
      # -------------------
      # This will add a conditional to the item specified
      # @param title text
      def authorized(title: 'Section title')
        render(SideMenu::Component.new(current_path: '/auth-1')) do |c|
          c.with_list(title: title) do |list|
            list.with_item(name: 'Authorized 1', authorized: true, href: '/auth-1')
            list.with_item(name: 'Authorized 2', authorized: true, href: '/auth-2')
            list.with_item(name: 'Not authorized 1', authorized: false, href: '/not-auth-1')
            list.with_item(name: 'Not authorized 2', authorized: false, href: '/not-auth-1')
          end
        end
      end

      # SideMenu with SubMenu
      # -------------------
      # This will add subitems to an item
      # @param title text
      def with_sub_item(title: 'Section title')
        render(SideMenu::Component.new(current_path: '/parent-item')) do |c|
          c.with_list(title: title) do |list|
            list.with_item(name: 'Parent Item', href: '/parent-item') do |item|
              item.with_item(name: 'Child Item 1', href: '/child-item-1')
              item.with_item(name: 'Child Item 2', href: '/child-item-2')
              item.with_item(name: 'Child Item 3', href: '/child-item-3')
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
          c.with_list(title: title) do |list|
            list.with_item(name: 'Parent Item', href: '/parent-item') do |item|
              item.with_item(name: 'Child Item 1', href: '/child-item-1')
              item.with_item(name: 'Child Item 2', href: '/child-item-2')
              item.with_item(name: 'Child Item 3', href: '/child-item-3')
            end
          end
        end
      end

      # SideMenu with Custom Link Content
      # -------------------
      def custom_link_content
        render(SideMenu::Component.new(current_path: '/child-item-1')) do |c|
          c.with_list(title: 'Title') do |list|
            list.with_item(href: '/parent-item') do
              safe_join([
                          tag.span('Custom Link', class: 'mr-3'),
                          tag.span('0', class: 'tag is-danger')
                        ])
            end
          end
        end
      end
    end
  end
end
