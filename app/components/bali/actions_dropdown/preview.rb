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
          c.with_item(name: 'Delete', icon: true, href: '#', method: :delete)
        end
      end

      # With Custom Content
      # ---------------
      # Custom HTML content inside the dropdown
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

      # Align Start (Default)
      # ---------------
      # Menu aligns to the start (left) of the trigger button
      def align_start
        render_with_template(template: 'bali/actions_dropdown/previews/align_start')
      end

      # Align Center
      # ---------------
      # Menu aligns to the center of the trigger button
      def align_center
        render_with_template(template: 'bali/actions_dropdown/previews/align_center')
      end

      # Align End
      # ---------------
      # Menu aligns to the end (right) of the trigger button
      def align_end
        render_with_template(template: 'bali/actions_dropdown/previews/align_end')
      end

      # Direction Top
      # ---------------
      # Menu opens above the trigger button
      def direction_top
        render_with_template(template: 'bali/actions_dropdown/previews/direction_top')
      end

      # Direction Bottom
      # ---------------
      # Menu opens below the trigger button
      def direction_bottom
        render_with_template(template: 'bali/actions_dropdown/previews/direction_bottom')
      end

      # Direction Left
      # ---------------
      # Menu opens to the left of the trigger button
      def direction_left
        render_with_template(template: 'bali/actions_dropdown/previews/direction_left')
      end

      # Direction Right
      # ---------------
      # Menu opens to the right of the trigger button
      def direction_right
        render_with_template(template: 'bali/actions_dropdown/previews/direction_right')
      end

      # Top + End
      # ---------------
      # Menu opens above and aligns to the end
      def top_end
        render_with_template(template: 'bali/actions_dropdown/previews/top_end')
      end

      # Bottom + End
      # ---------------
      # Menu opens below and aligns to the end
      def bottom_end
        render_with_template(template: 'bali/actions_dropdown/previews/bottom_end')
      end
    end
  end
end
