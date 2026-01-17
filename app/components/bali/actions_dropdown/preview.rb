# frozen_string_literal: true

module Bali
  module ActionsDropdown
    class Preview < ApplicationViewComponentPreview
      # Default Actions Dropdown
      # ---------------
      # Dropdown menu for row-level actions with icon trigger.
      # Items with `method: :delete` automatically use DeleteLink with confirmation.
      def default
        render ActionsDropdown::Component.new do |c|
          c.with_item(name: 'Edit', icon_name: 'edit', href: '#')
          c.with_item(name: 'Export', icon_name: 'file-export', href: '#')
          c.with_item(name: 'Delete', icon: true, href: '#', method: :delete)
        end
      end

      # @param align select { choices: [start, center, end] }
      # @param direction select { choices: [~, top, bottom, left, right] }
      # @param width select { choices: [sm, md, lg, xl] }
      # Playground
      # ---------------
      # Explore different alignments, directions, and widths.
      # **Alignment** controls horizontal position (start/center/end).
      # **Direction** controls where menu opens (top/bottom/left/right).
      # **Width** controls menu width (sm=10rem, md=13rem, lg=16rem, xl=20rem).
      def playground(align: :start, direction: nil, width: :md)
        render_with_template(locals: {
          align: align.to_sym,
          direction: direction.presence&.to_sym,
          width: width.to_sym
        })
      end

      # With Custom Trigger
      # ---------------
      # Override the default ellipsis icon with a custom trigger button.
      # Use `with_trigger` slot to provide any element as the dropdown trigger.
      def with_custom_trigger
        render ActionsDropdown::Component.new do |c|
          c.with_trigger do
            tag.div('Actions ▾', tabindex: 0, role: 'button', class: 'btn btn-sm btn-outline')
          end
          c.with_item(name: 'Edit', icon_name: 'edit', href: '#')
          c.with_item(name: 'Export', icon_name: 'file-export', href: '#')
          c.with_item(name: 'Delete', icon: true, href: '#', method: :delete)
        end
      end

      # With Custom Icon
      # ---------------
      # Change the default trigger icon using the `icon` parameter.
      # Useful when you want vertical ellipsis or another icon.
      def with_custom_icon
        render ActionsDropdown::Component.new(icon: 'more') do |c|
          c.with_item(name: 'Edit', icon_name: 'edit', href: '#')
          c.with_item(name: 'Delete', icon: true, href: '#', method: :delete)
        end
      end

      # With Custom Content
      # ---------------
      # Pass block content directly for full control over menu items.
      # Use this when items slot doesn't fit your needs.
      def with_custom_content
        render ActionsDropdown::Component.new do |c|
          c.safe_join([
            c.tag.li(c.render(Bali::Link::Component.new(
              name: 'Create',
              icon_name: 'plus-circle',
              href: '#',
              drawer: true
            ))),
            c.tag.li(c.render(Bali::Link::Component.new(
              name: 'Export',
              icon_name: 'file-export',
              href: '#',
              drawer: true
            )))
          ])
        end
      end
    end
  end
end
