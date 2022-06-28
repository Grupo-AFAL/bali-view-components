module Bali
  module SideMenu
    class Preview < ApplicationViewComponentPreview
      def default
        render(SideMenu::Component.new) do |c|
          c.list(title: 'Section Title') do |list|
            list.item(name: 'Item', href: '#')
          end
        end
      end

      def with_icon
        render(SideMenu::Component.new) do |c|
          c.list(title: 'Section title') do |list|
            list.item(name: 'Item', href: '#', icon: 'attachment')
          end
        end
      end

      def authorized
        render(SideMenu::Component.new) do |c|
          c.list(title: 'Section title') do |list|
            list.item(name: 'Authorized item', authorized: true, href: '#')
            list.item(name: 'Unauthorized item', authorized: false, href: '#')
          end
        end
      end

      def with_sub_item
        render(SideMenu::Component.new) do |c|
          c.list(title: 'Section title') do |list|
            list.item(name: 'Item', href: '#') do |item|
              item.child_item(name: 'Subitem 1', href: '#')
              item.child_item(name: 'Subitem 2', href: '#')
            end
          end
        end
      end
    end
  end
end
