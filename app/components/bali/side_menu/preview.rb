module Bali
  module SideMenu
    class Preview < ApplicationViewComponentPreview
      # Simple SideMenu
      # -------------------
      # Default menu with a section name and an item
      # @param title text
      # @param name text
      def default(title: 'Section Title', name: 'Item')
        render(SideMenu::Component.new) do |c|
          c.list(title: title) do |list|
            list.item(name: name, href: '#')
          end
        end
      end

      # SideMenu with icon in the item
      # -------------------
      # This will add an icon in the item specified
      # @param title text
      # @param name text
      # @param icon_name select [attachment, alert, paypal]
      def with_icon(title: 'Section title', name: 'Item', icon_name: 'attachment')
        render(SideMenu::Component.new) do |c|
          c.list(title: title) do |list|
            list.item(name: name, href: '#', icon: icon_name)
          end
        end
      end

      # SideMenu with conditional
      # -------------------
      # This will add a conditional to the item specified
      # @param title text
      # @param name text
      # @param authorized select [true, false]
      def authorized(title: 'Section title', name: 'Authorized Item', authorized: true)
        render(SideMenu::Component.new) do |c|
          c.list(title: title) do |list|
            list.item(name: name, authorized: authorized, href: '#')
          end
        end
      end

      # SideMenu with SubMenu
      # -------------------
      # This will add subitems to an item
      # @param title text
      # @param name text
      # @param subitem_1 text
      def with_sub_item(title: 'Section title', name: 'Item', subitem_1: 'Subitem 1')
        render(SideMenu::Component.new) do |c|
          c.list(title: title) do |list|
            list.item(name: name, href: '#') do |item|
              item.child_item(name: subitem_1, href: '#')
            end
          end
        end
      end
    end
  end
end
